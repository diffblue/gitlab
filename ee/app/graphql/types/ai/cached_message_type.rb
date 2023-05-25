# frozen_string_literal: true

module Types
  module Ai
    # rubocop: disable Graphql/AuthorizeTypes
    class CachedMessageType < Types::BaseObject
      graphql_name 'AiCachedMessageType'

      field :id,
        GraphQL::Types::ID,
        description: 'UUID of the message.'

      field :request_id,
        GraphQL::Types::ID,
        description: 'UUID of the original request message.'

      field :content,
        GraphQL::Types::String,
        null: true,
        description: 'Content of the message. Can be null for user requests or failed responses.'

      field :role,
        Types::Ai::CachedMessageRoleEnum,
        null: false,
        description: 'Message role.'

      field :timestamp,
        Types::TimeType,
        null: false,
        description: 'Message timestamp.'

      field :errors,
        [GraphQL::Types::String],
        null: false,
        description: 'Errors that occurred while asynchronously fetching an AI(assistant) response.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
