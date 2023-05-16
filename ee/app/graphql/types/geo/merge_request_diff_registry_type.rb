# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class MergeRequestDiffRegistryType < BaseObject
      graphql_name 'MergeRequestDiffRegistry'
      description 'Represents the Geo sync and verification state of a Merge Request diff'

      include ::Types::Geo::RegistryType

      field :merge_request_diff_id, GraphQL::Types::ID, null: false, description: 'ID of the Merge Request diff.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
