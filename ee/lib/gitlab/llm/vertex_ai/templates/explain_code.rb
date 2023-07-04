# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module Templates
        class ExplainCode
          TEMPERATURE = 0.3
          AUTHOR_MAP = { 'assistant' => 'content', 'user' => 'user' }.freeze
          SYSTEM = 'system'

          class << self
            def get_options(messages)
              {
                instances: [
                  messages: transformed_messages(messages)
                ],
                parameters: Configuration.default_payload_parameters.merge(
                  temperature: TEMPERATURE,
                  maxOutputTokens: ::Llm::ExplainCodeService::MAX_RESPONSE_TOKENS
                )
              }
            end

            private

            # ExplainCodeInputType accepts input in the OpenAI format
            # This method transforms the input to VertexAI format
            def transformed_messages(messages)
              system_message = nil

              messages.map! do |message|
                message = message.with_indifferent_access
                author = message.delete(:role)

                # If the input contains system message, append it to the next user message
                if author == SYSTEM
                  system_message = message[:content]
                  next
                end

                if system_message.present?
                  message[:content] = "#{system_message}\n#{message[:content]}"
                  system_message = nil
                end

                message[:author] = AUTHOR_MAP[author]

                message
              end.compact!

              messages
            end
          end
        end
      end
    end
  end
end
