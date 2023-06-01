# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      class ResponseModifier < Gitlab::Llm::BaseResponseModifier
        def initialize(answer)
          @ai_response = answer
        end

        def response_body
          @response_body ||= ai_response.content
        end

        def errors
          @errors ||= ai_response.status == :error ? [ai_response.content] : []
        end
      end
    end
  end
end
