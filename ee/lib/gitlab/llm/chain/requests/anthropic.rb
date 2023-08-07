# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Requests
        class Anthropic < Base
          attr_reader :ai_client

          TEMPERATURE = 0.1
          STOP_WORDS = ["\n\nHuman", "Observation:"].freeze
          PROMPT_SIZE = 30_000

          def initialize(user)
            @ai_client = ::Gitlab::Llm::Anthropic::Client.new(user)
          end

          def request(prompt)
            ai_client.complete(
              prompt: prompt[:prompt],
              **default_options.merge(prompt.fetch(:options, {}))
            )&.dig("completion").to_s.strip
          end

          private

          def default_options
            {
              temperature: TEMPERATURE,
              stop_sequences: STOP_WORDS
            }
          end
        end
      end
    end
  end
end
