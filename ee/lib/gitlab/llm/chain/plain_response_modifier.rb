# frozen_string_literal: true

module Gitlab
  module Llm
    module Chain
      class PlainResponseModifier < Gitlab::Llm::BaseResponseModifier
        def initialize(answer)
          @ai_response = answer
        end

        def response_body
          @ai_response
        end

        def errors
          []
        end
      end
    end
  end
end
