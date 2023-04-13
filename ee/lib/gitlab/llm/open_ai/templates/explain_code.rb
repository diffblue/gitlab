# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module Templates
        class ExplainCode
          TEMPERATURE = 0.3

          def self.get_options(messages)
            {
              messages: messages,
              max_tokens: ::Llm::ExplainCodeService::MAX_RESPONSE_TOKENS,
              temperature: TEMPERATURE
            }
          end
        end
      end
    end
  end
end
