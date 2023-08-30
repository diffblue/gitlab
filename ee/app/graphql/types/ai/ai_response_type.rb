# frozen_string_literal: true

module Types
  module Ai
    # rubocop: disable Graphql/AuthorizeTypes
    class AiResponseType < BaseObject
      graphql_name 'AiResponse'

      field :response_body, GraphQL::Types::String,
        null: true,
        description: 'Response body from AI API.'

      field :response_body_html, GraphQL::Types::String,
        null: true,
        description: 'Response body HTML.'

      field :request_id, GraphQL::Types::String,
        null: true,
        description: 'ID of the original request.'

      field :role,
        Types::Ai::ChatMessageRoleEnum,
        null: false,
        description: 'Message role.'

      field :type, GraphQL::Types::String,
        null: true,
        description: 'Message type.'

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

      field :extras,
        Types::Ai::MessageExtrasType,
        null: true,
        description: 'Extra message metadata.'

      def response_body_html
        banzai_options = {
          current_user: current_user,
          only_path: false,
          pipeline: :full,
          allow_comments: false,
          skip_project_check: true
        }

        Banzai.render_and_post_process(object[:response_body], banzai_options)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
