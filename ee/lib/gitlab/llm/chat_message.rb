# frozen_string_literal: true

module Gitlab
  module Llm
    class ChatMessage
      ROLE_USER = 'user'
      ROLE_ASSISTANT = 'assistant'
      ROLE_SYSTEM = 'system'
      ALLOWED_ROLES = [ROLE_USER, ROLE_ASSISTANT, ROLE_SYSTEM].freeze

      attr_reader :id, :request_id, :content, :role, :timestamp, :error, :extras

      RESET_MESSAGE = '/reset'

      def initialize(data)
        @id = data['id']
        @request_id = data['request_id']
        @content = data['content']
        @role = data['role']
        @error = data['error']
        @timestamp = Time.zone.parse(data['timestamp'])
        @extras = ::Gitlab::Json.parse(data['extras']) if data['extras']
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
