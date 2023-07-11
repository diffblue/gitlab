# frozen_string_literal: true

module Gitlab
  module Llm
    module ResponseModifiers
      class ToolAnswer < ::Gitlab::Llm::BaseResponseModifier
        def response_body
          @response_body ||= ai_response&.dig(:content)
        end

        def errors
          @errors ||= []
        end
      end
    end
  end
end
