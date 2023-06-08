# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      module Requests
        class VertexAi
          attr_reader :ai_client

          TEMPERATURE = 0.0

          def initialize(user)
            @ai_client = ::Gitlab::Llm::VertexAi::Client.new(user)
          end

          def request(prompt)
            params = ::Gitlab::Llm::VertexAi::Configuration.default_payload_parameters.merge(
              temperature: TEMPERATURE
            )

            ai_client.text(
              content: prompt,
              parameters: { **params }
            )&.dig("predictions", 0, "content").to_s.strip
          end
        end
      end
    end
  end
end
