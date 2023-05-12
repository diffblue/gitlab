# frozen_string_literal: true

module Gitlab
  module Llm
    class BaseResponseModifier
      attr_accessor :ai_response

      def initialize(ai_response)
        @ai_response = Gitlab::Json.parse(ai_response)&.with_indifferent_access
      end

      def response_body
        raise NotImplementedError
      end

      def errors
        raise NotImplementedError
      end
    end
  end
end
