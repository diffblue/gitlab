# frozen_string_literal: true

module Gitlab
  module Llm
    module OpenAi
      module ResponseModifiers
        class Chat < ::Gitlab::Llm::BaseResponseModifier
          def response_body
            @response_body ||= ai_response&.dig(:choices, 0, :message, :content).to_s.strip
          end

          def errors
            @errors ||= [ai_response&.dig(:error)].compact
          end
        end
      end
    end
  end
end
