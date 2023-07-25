# frozen_string_literal: true

module Gitlab
  module Llm
    module ResponseModifiers
      class EmptyResponseModifier < ::Gitlab::Llm::BaseResponseModifier
        def initialize(_ai_response)
          @ai_response = {}
        end

        def response_body
          @response_body ||= ""
        end

        def errors
          @errors ||= [_('Chat not available.')]
        end
      end
    end
  end
end
