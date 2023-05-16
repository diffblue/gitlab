# frozen_string_literal: true

module Gitlab
  module Llm
    class OpenAiChatResponse
      def initialize(raw_response)
        @raw_response = raw_response
      end

      def content
        @content ||= body&.dig(:choices, 0, :message, :content)
      end

      def error_code
        @error_code ||= body.dig(:error, :code)
      end

      def finish_reason
        @finish_reason ||= body.dig(:choices, 0, :finish_reason)
      end

      def error_message
        @error_message ||= body.dig(:error, :message)
      end

      private

      def body
        @body ||= Gitlab::Json.parse(@raw_response)&.with_indifferent_access
      end
    end
  end
end
