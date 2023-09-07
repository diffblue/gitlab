# frozen_string_literal: true

module Types
  module Ai
    # rubocop: disable Graphql/AuthorizeTypes
    class MessageExtrasType < Types::BaseObject
      graphql_name 'AiMessageExtras'
      description "Extra metadata for AI message."

      field :sources, [GraphQL::Types::JSON],
        null: true,
        description: "Sources used to form the message."
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
