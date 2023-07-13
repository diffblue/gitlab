# frozen_string_literal: true

module Types
  module Ai
    class ChatInputType < BaseMethodInputType
      graphql_name 'AiChatInput'

      argument :resource_id,
        ::Types::GlobalIDType[::Ai::Model],
        required: false,
        description: "Global ID of the resource to mutate."

      argument :namespace_id,
        ::Types::GlobalIDType[::Namespace],
        required: false,
        description: "Global ID of the namespace the user is acting on."

      argument :content, GraphQL::Types::String,
        required: true,
        validates: { allow_blank: false },
        description: 'Content of the message.'
    end
  end
end
