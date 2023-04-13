# frozen_string_literal: true

module Types
  module Ai
    class ExplainCodeInputType < BaseMethodInputType
      graphql_name 'AiExplainCodeInput'

      class MessageInput < Types::BaseInputObject
        graphql_name 'AiExplainCodeMessageInput'

        argument :role, GraphQL::Types::String,
          required: true,
          description: 'Role of the message (system, user, assistant).'

        argument :content, GraphQL::Types::String,
          required: true,
          description: 'Content of the message.'
      end

      argument :messages, [MessageInput],
        required: true,
        validates: { allow_blank: false },
        description: 'Code messages that is passed to be explained by AI.'
    end
  end
end
