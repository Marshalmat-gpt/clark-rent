# Orchestrateur Claude — appelle l'API Anthropic via le gem `anthropic`.
# Conserve une interface simple pour l'instant : un message utilisateur
# en entrée, une réponse texte en sortie. La sélection d'outils
# (tool use) sera ajoutée quand les premiers cas d'usage seront finalisés.
#
# Usage :
#   reply = ClarkAgent::Orchestrator.new(user: current_user).chat('Bonjour')
#
# En CI/test, l'API n'est pas appelée : on stub `Orchestrator#chat`.
module ClarkAgent
  class Orchestrator
    DEFAULT_MODEL = 'claude-sonnet-4-6'.freeze
    MAX_TOKENS    = 1024

    attr_reader :user, :model

    def initialize(user:, model: DEFAULT_MODEL)
      @user  = user
      @model = model
    end

    def chat(message, history: [])
      response = client.messages(
        parameters: {
          model: model,
          max_tokens: MAX_TOKENS,
          system: system_prompt,
          messages: history + [{ role: 'user', content: message.to_s }]
        }
      )

      extract_text(response)
    end

    def system_prompt
      <<~PROMPT
        Tu es Clark, l'agent virtuel de la plateforme de gestion locative Clark Rent.
        L'utilisateur courant est #{user.first_name} (#{user.role}).
        Réponds en français, de façon concise et factuelle.
      PROMPT
    end

    private

    def client
      @client ||= Anthropic::Client.new(access_token: ENV.fetch('ANTHROPIC_API_KEY', ''))
    end

    def extract_text(response)
      content = response.is_a?(Hash) ? response['content'] : response
      return '' unless content.is_a?(Array)

      content.filter_map { |block| block['text'] || block[:text] }.join("\n").strip
    end
  end
end
