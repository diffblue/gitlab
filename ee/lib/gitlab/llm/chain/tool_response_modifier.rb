# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      class ToolResponseModifier < Gitlab::Llm::BaseResponseModifier
        def initialize(tool_class)
          @ai_response = tool_class
        end

        def response_body
          @response_body ||= ai_response::HUMAN_NAME
        end

        def errors
          @errors ||= []
        end
      end
    end
  end
end
