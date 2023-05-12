# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module ResponseModifiers
        class Completions < ::Gitlab::Llm::BaseResponseModifier
          def response_body
            @response_body ||= ai_response&.dig(:choices, 0, :text).to_s.strip
          end

          def errors
            @errors ||= [ai_response&.dig(:error)].compact
          end
        end
      end
    end
  end
end
