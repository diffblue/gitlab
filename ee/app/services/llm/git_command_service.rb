# frozen_string_literal: true

module Llm
  class GitCommandService < BaseService
    TEMPERATURE = 0.4
    INPUT_CONTENT_LIMIT = 300
    MAX_RESPONSE_TOKENS = 200
    OPENAI = 'openai'
    VERTEXAI = 'vertexai'

    def valid?
      super &&
        ::License.feature_available?(:ai_git_command) &&
        Feature.enabled?(:ai_git_command_ff, user) &&
        options[:prompt].size < INPUT_CONTENT_LIMIT
    end

    private

    def perform
      payload =
        if options[:model] == VERTEXAI
          config =
            ::Gitlab::Llm::VertexAi::Configuration.new(
              model_config: ::Gitlab::Llm::VertexAi::ModelConfigurations::CodeChat.new
            )

          { url: config.url, headers: config.headers, body: config.payload(prompt).to_json }
        else
          ::Gitlab::Llm::OpenAi::Options.new.chat(
            content: json_prompt,
            temperature: TEMPERATURE,
            max_tokens: MAX_RESPONSE_TOKENS
          )
        end

      success(payload)
    end

    def prompt
      <<~TEMPLATE
      Provide the appropriate git commands for: #{options[:prompt]}.
      TEMPLATE
    end

    def json_prompt
      <<~TEMPLATE
      Provide the appropriate git commands for: #{options[:prompt]}.
      Respond with JSON format
      ##
      {
        "commands": [The list of commands],
        "explanation": The explanation with the commands wrapped in backticks
      }
      TEMPLATE
    end
  end
end
