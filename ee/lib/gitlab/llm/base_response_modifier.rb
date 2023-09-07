# frozen_string_literal: true

module Gitlab
  module Llm
    class BaseResponseModifier
      attr_accessor :ai_response

      # Due to a difference in the implementation of the Anthropic
      # and VertexAi clients where the `stream_body` parameter is
      # only passed to one of them, it is possible for the ai_response
      # to behave as a parsed Hash object, or an unparsed json string object.
      #
      # https://gitlab.com/gitlab-org/gitlab/-/issues/422519 is to follow up
      # and make these clients behave consistently with each other and simplify
      # the initializer.

      def initialize(ai_response)
        @ai_response = if ai_response.respond_to?(:keys)
                         ai_response
                       else
                         Gitlab::Json.parse(ai_response)
                       end&.with_indifferent_access
      end

      def response_body
        raise NotImplementedError
      end

      def errors
        raise NotImplementedError
      end

      def extras
        nil
      end
    end
  end
end
