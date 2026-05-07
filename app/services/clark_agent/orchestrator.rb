# Orchestrateur Claude — appelle l'API Anthropic via le gem `anthropic`
# avec une boucle "tool use" :
#   1. envoie le message + la liste des outils ;
#   2. si Claude répond avec stop_reason=tool_use, exécute les outils
#      via ToolRegistry et renvoie les résultats ;
#   3. répète jusqu'à stop_reason=end_turn (ou MAX_ITERATIONS atteint).
#
# Usage :
#   reply = ClarkAgent::Orchestrator.new(user: current_user).chat('Quels sont mes tickets ouverts ?')
#
# En CI/test, l'API n'est pas appelée : on stub `Orchestrator#chat`.
module ClarkAgent
  class Orchestrator
    DEFAULT_MODEL  = 'claude-sonnet-4-6'.freeze
    MAX_TOKENS     = 1024
    MAX_ITERATIONS = 5

    attr_reader :user, :model

    def initialize(user:, model: DEFAULT_MODEL)
      @user  = user
      @model = model
    end

    def chat(message, history: [])
      messages = history + [{ role: 'user', content: message.to_s }]
      MAX_ITERATIONS.times do
        response = call_api(messages)
        return extract_text(response) if stop?(response)

        tool_uses = tool_use_blocks(response)
        break if tool_uses.empty?

        messages << { role: 'assistant', content: response['content'] }
        messages << { role: 'user',      content: run_tools(tool_uses) }
      end
      'Je n\'ai pas pu finaliser la requête (limite d\'itérations atteinte).'
    end

    def system_prompt
      <<~PROMPT
        Tu es Clark, l'agent virtuel de la plateforme de gestion locative Clark Rent.
        L'utilisateur courant est #{user.first_name} (#{user.role}).
        Réponds en français, de façon concise et factuelle. Utilise les
        outils disponibles pour lire ou modifier les données, plutôt que
        d'inventer une réponse.
      PROMPT
    end

    private

    def call_api(messages)
      client.messages(
        parameters: {
          model: model,
          max_tokens: MAX_TOKENS,
          system: system_prompt,
          tools: ToolRegistry.tool_specs,
          messages: messages
        }
      )
    end

    def stop?(response)
      response['stop_reason'] == 'end_turn'
    end

    def tool_use_blocks(response)
      content = response['content']
      return [] unless content.is_a?(Array)

      content.select { |b| b['type'] == 'tool_use' }
    end

    def run_tools(blocks)
      blocks.map do |block|
        tool = ToolRegistry.find(block['name'])
        result = if tool
                   safe_call(tool, block['input'] || {})
                 else
                   { error: "Unknown tool #{block['name']}" }
                 end
        {
          type: 'tool_result',
          tool_use_id: block['id'],
          content: result.to_json
        }
      end
    end

    def safe_call(tool, input)
      tool.handler.call(user: user, **input.transform_keys(&:to_sym))
    rescue StandardError => e
      { error: "#{e.class}: #{e.message}" }
    end

    def client
      @client ||= Anthropic::Client.new(access_token: ENV.fetch('ANTHROPIC_API_KEY', ''))
    end

    def extract_text(response)
      content = response['content']
      return '' unless content.is_a?(Array)

      content.filter_map { |b| b['text'] }.join("\n").strip
    end
  end
end
