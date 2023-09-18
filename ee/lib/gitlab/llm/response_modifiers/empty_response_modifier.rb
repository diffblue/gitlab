# frozen_string_literal: true

module Gitlab
  module Llm
    module ResponseModifiers
      class EmptyResponseModifier < ::Gitlab::Llm::BaseResponseModifier
        def initialize(message = nil)
          @ai_response = { message: message }
        end

        def response_body
          @response_body ||= ai_response[:message] || ""
        end

        def errors
          @errors ||= []
        end
      end
    end
  end
end
