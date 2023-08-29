# frozen_string_literal: true

module Types
  module Ai
    # rubocop: disable Graphql/AuthorizeTypes
    class AiResponseType < BaseObject
      graphql_name 'AiResponse'

      # rubocop:disable GraphQL/FieldHashKey
      field :id,
        GraphQL::Types::ID,
        description: 'UUID of the message.'
      # rubocop:enable GraphQL/FieldHashKey

      field :request_id, GraphQL::Types::String,
        null: true,
        description: 'ID of the original request.'

      field :content, GraphQL::Types::String,
        null: true,
        description: 'Raw response content.'

      field :content_html, GraphQL::Types::String,
        null: true,
        description: 'Response content as HTML.'

      field :response_body, GraphQL::Types::String,
        null: true,
        description: 'Response body from AI API.',
        deprecated: { reason: 'Moved to content attribute', milestone: '16.4' }, hash_key: :content

      field :response_body_html, GraphQL::Types::String,
        null: true,
        description: 'Response body HTML.',
        deprecated: { reason: 'Moved to contentHtml attribute', milestone: '16.4' }

      field :role,
        Types::Ai::ChatMessageRoleEnum,
        null: false,
        description: 'Message role.'

      field :timestamp,
        Types::TimeType,
        null: false,
        description: 'Message timestamp.'

      field :chunk_id,
        GraphQL::Types::Int,
        null: true,
        description: 'Incremental ID for a chunk from a streamed response. Null when it is not a streamed response.'

      field :errors, [GraphQL::Types::String],
        null: true,
        description: 'Errors return by AI API as response.'

      field :type, Types::Ai::MessageTypesEnum,
        null: true,
        description: 'Message type.'

      field :extras,
        Types::Ai::MessageExtrasType,
        null: true,
        description: 'Extra message metadata.'

      def id
        object[:id] # Temporary solution before we introduce AiMessage model.
      end

      def content_html
        banzai_options = {
          current_user: current_user,
          only_path: false,
          pipeline: :full,
          allow_comments: false,
          skip_project_check: true
        }

        Banzai.render_and_post_process(object[:content], banzai_options)
      end

      def response_body_html
        content_html
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
