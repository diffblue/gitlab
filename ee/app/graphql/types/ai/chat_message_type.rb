# frozen_string_literal: true

module Types
  module Ai
    # rubocop: disable Graphql/AuthorizeTypes
    class ChatMessageType < Types::BaseObject
      graphql_name 'AiChatMessage'
      description "Duo Chat message"

      field :id,
        GraphQL::Types::ID,
        description: 'UUID of the message.'

      field :request_id,
        GraphQL::Types::ID,
        description: 'UUID of the original request message. Shared between chat prompt and response.'

      field :content,
        GraphQL::Types::String,
        null: true,
        description: 'Content of the message. Can be null for failed responses.'

      field :content_html,
        GraphQL::Types::String,
        null: true,
        description: 'Content of the message in HTML format. Can be null for failed responses.'

      field :role,
        Types::Ai::ChatMessageRoleEnum,
        null: false,
        description: 'Message role.'

      field :timestamp,
        Types::TimeType,
        null: false,
        description: 'Message timestamp.'

      field :errors,
        [GraphQL::Types::String],
        null: false,
        description: 'Errors that occurred while asynchronously fetching an AI (assistant) response.'

      field :extras,
        Types::Ai::MessageExtrasType,
        null: true,
        description: 'Extra message metadata.'

      def content_html
        banzai_options = {
          current_user: current_user,
          only_path: false,
          pipeline: :full,
          allow_comments: false,
          skip_project_check: true
        }

        Banzai.render_and_post_process(object.content, banzai_options)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
