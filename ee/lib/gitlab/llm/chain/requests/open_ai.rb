# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Requests
        class OpenAi < Base
          attr_reader :ai_client

          TEMPERATURE = 0.2
          MAX_TOKENS = 4096

          def initialize(user)
            @ai_client = ::Gitlab::Llm::OpenAi::Client.new(user)
          end

          def request(prompt)
            ai_client.completions(
              prompt: prompt[:prompt],
              **default_options.merge(prompt.fetch(:options, {}))
            )&.dig("choices", 0, "text").to_s.strip
          end

          private

          def default_options
            {
              moderated: false,
              max_tokens: MAX_TOKENS,
              temperature: TEMPERATURE
            }
          end
        end
      end
    end
  end
end
