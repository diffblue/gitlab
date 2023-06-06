# frozen_string_literal: true

module Resolvers
  module Ai
    class MessagesResolver < BaseResolver
      type Types::Ai::CachedMessageType, null: false

      argument :request_ids, [GraphQL::Types::ID],
        required: false,
        description: 'Array of request IDs to fetch.'

      argument :roles, [Types::Ai::CachedMessageRoleEnum],
        required: false,
        description: 'Array of roles to fetch.'

      def resolve(**args)
        return [] unless current_user

        ::Gitlab::Llm::Cache.new(current_user).find_all(args)
      end
    end
  end
end
