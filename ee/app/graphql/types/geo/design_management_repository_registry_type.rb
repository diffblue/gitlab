# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class DesignManagementRepositoryRegistryType < BaseObject
      graphql_name 'DesignManagementRepositoryRegistry'

      include ::Types::Geo::RegistryType

      description 'Represents the Geo replication and verification state of a Design Management Repository'

      field :design_management_repository_id, GraphQL::Types::ID, null: false,
        description: 'ID of the Design Management Repository.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
