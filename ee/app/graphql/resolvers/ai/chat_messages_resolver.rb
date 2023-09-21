# frozen_string_literal: true

module Resolvers
  module Ai
    class ChatMessagesResolver < BaseResolver
      type Types::Ai::MessageType, null: false

      argument :request_ids, [GraphQL::Types::ID],
        required: false,
        description: 'Array of request IDs to fetch.'

      argument :roles, [Types::Ai::MessageRoleEnum],
        required: false,
        description: 'Array of roles to fetch.'

      def resolve(**args)
        return [] unless current_user

        ::Gitlab::Llm::ChatStorage.new(current_user).messages(args)
      end
    end
  end
end
