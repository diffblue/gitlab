# frozen_string_literal: true

module Types
  module SecurityOrchestration
    # rubocop: disable Graphql/AuthorizeTypes
    class ApprovalGroupType < BaseObject
      # rubocop: enable Graphql/AuthorizeTypes
      graphql_name 'PolicyApprovalGroup'

      authorize []

      field :id, GraphQL::Types::ID,
        null: false,
        description: 'ID of the namespace.'

      field :full_path, GraphQL::Types::ID,
        null: false,
        description: 'Full path of the namespace.'

      field :web_url,
        type: GraphQL::Types::String,
        null: false,
        description: 'Web URL of the group.'

      field :avatar_url,
        type: GraphQL::Types::String,
        null: true,
        description: 'Avatar URL of the group.'
    end
  end
end
