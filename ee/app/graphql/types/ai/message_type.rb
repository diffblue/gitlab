# frozen_string_literal: true

module Types
  module Ai
    class MessageType < Types::BaseObject
      graphql_name 'AiMessageType'

      authorize :read_ai_message

      field :id,
        GraphQL::Types::ID,
        description: 'Global ID of the message.'

      field :role,
        GraphQL::Types::String,
        null: false,
        description: 'Role of the message (system, user, assistant).'

      field :content,
        GraphQL::Types::String,
        null: true,
        description: 'Content of the message or null if loading.'

      field :errors,
        [GraphQL::Types::String],
        null: false,
        description: 'Errors that occurred while asynchronously fetching an AI(assistant) response.',
        method: :async_errors

      field :is_fetching,
        GraphQL::Types::Boolean,
        null: true,
        description: 'Whether the content is still being fetched, for a message with the assistant role.',
        method: :fetching?
    end
  end
end
