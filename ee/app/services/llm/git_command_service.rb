# frozen_string_literal: true

module Llm
  class GitCommandService < BaseService
    INPUT_CONTENT_LIMIT = 300
    MAX_RESPONSE_TOKENS = 300

    def valid?
      super &&
        ::License.feature_available?(:ai_git_command) &&
        Feature.enabled?(:ai_git_command_ff, user) &&
        options[:prompt].size < INPUT_CONTENT_LIMIT
    end

    private

    def perform
      prompt = <<~TEMPLATE
      Provide the appropriate git commands for: #{options[:prompt]}.
      Respond with JSON format
      ##
      {
        "commands": [The list of commands],
        "explanation": The explanation with the commands wrapped in backticks
      }
      TEMPLATE

      options = {
        temperature: 0.4,
        max_tokens: MAX_RESPONSE_TOKENS
      }

      success(::Gitlab::Llm::OpenAi::Options.new.chat(content: prompt, **options))
    end
  end
end
