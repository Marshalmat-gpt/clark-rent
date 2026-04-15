module ClarkAgent
  class Orchestrator
    MAX_TOOL_ROUNDS = 5

    def self.run(system:, history:, message:, user:, role:)
      client   = Anthropic::Client.new(api_key: ENV['ANTHROPIC_API_KEY'])
      tools    = ClarkAgent::ToolDefinitions.all
      messages = history + [{ role: 'user', content: message }]
      actions  = []

      MAX_TOOL_ROUNDS.times do
        response = client.messages(
          model:      'claude-sonnet-4-20250514',
          max_tokens: 1024,
          system:     system,
          tools:      tools,
          messages:   messages
        )

        messages << { role: 'assistant', content: response.content }

        # Réponse finale — pas d'outil appelé
        break if response.stop_reason == 'end_turn'

        # Exécuter les tool calls
        tool_results = []
        response.content.each do |block|
          next unless block.type == 'tool_use'

          result = ClarkAgent::ToolExecutor.execute(
            name:  block.name,
            input: block.input,
            user:  user,
            role:  role
          )

          actions << result[:action] if result[:action]

          tool_results << {
            type:        'tool_result',
            tool_use_id: block.id,
            content:     result[:content].to_json
          }
        end

        messages << { role: 'user', content: tool_results }
      end

      last_text = messages.last[:content]
        .then { |c| c.is_a?(Array) ? c.find { |b| b[:type] == 'text' }&.dig(:text) : c }

      { reply: last_text, actions: actions, history: messages }
    end
  end
end
