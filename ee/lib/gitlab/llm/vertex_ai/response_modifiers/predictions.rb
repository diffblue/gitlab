# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      module ResponseModifiers
        class Predictions < ::Gitlab::Llm::BaseResponseModifier
          def response_body
            @response_body ||= ai_response&.dig(:predictions, 0, :candidates, 0, :content).to_s.strip
          end

          def errors
            @errors ||= [ai_response&.dig(:error, :message)].compact
          end
        end
      end
    end
  end
end
