# frozen_string_literal: true

module Types
  module Ai
    class ChatInputType < BaseMethodInputType
      graphql_name 'AiChatInput'

      argument :content, GraphQL::Types::String,
        required: true,
        validates: { allow_blank: false },
        description: 'Content of the message.'
    end
  end
end
