# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Requests
        class Anthropic
          attr_reader :ai_client

          TEMPERATURE = 0.0
          STOP_WORDS = ["\n\nHuman", "Observation:"].freeze

          def initialize(user)
            @ai_client = ::Gitlab::Llm::Anthropic::Client.new(user)
          end

          def request(prompt)
            ai_client.complete(
              prompt: prompt,
              temperature: TEMPERATURE,
              stop_sequences: STOP_WORDS
            )&.dig("completion").to_s.strip
          end
        end
      end
    end
  end
end
