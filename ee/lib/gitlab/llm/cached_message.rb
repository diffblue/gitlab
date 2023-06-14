# frozen_string_literal: true

module Gitlab
  module Llm
    class CachedMessage
      attr_reader :id, :request_id, :content, :role, :timestamp, :error

      RESET_MESSAGE = '/reset'

      def initialize(data)
        @id = data['id']
        @request_id = data['request_id']
        @content = data['content']
        @role = data['role']
        @error = data['error']
        @timestamp = Time.zone.parse(data['timestamp'])
      end

      def to_global_id
        ::Gitlab::GlobalId.build(self)
      end

      def errors
        Array.wrap(error)
      end

      def conversation_reset?
        content == RESET_MESSAGE
      end

      def size
        content&.size.to_i
      end
    end
  end
end
