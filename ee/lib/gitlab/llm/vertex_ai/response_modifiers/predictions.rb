# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module ResponseModifiers
        class Predictions < ::Gitlab::Llm::BaseResponseModifier
          include Gitlab::Utils::StrongMemoize

          def response_body
            predictions = ai_response&.dig(:predictions, 0)

            return '' unless predictions

            content = if predictions.has_key?(:candidates)
                        predictions.dig(:candidates, 0, :content)
                      else
                        # Gitlab::Llm::VertexAi::Client#text response doesn't include `candidates`.
                        predictions[:content]
                      end

            content.to_s.strip
          end
          strong_memoize_attr :response_body

          def errors
            @errors ||= [ai_response&.dig(:error, :message)].compact
          end
        end
      end
    end
  end
end
