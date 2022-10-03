# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class ContainerRepositoryRegistryType < BaseObject
      graphql_name 'ContainerRepositoryRegistry'
      description 'Represents the Geo replication and verification state of an Container Repository.'

      include ::Types::Geo::RegistryType

      field :container_repository_id, GraphQL::Types::ID, null: false, description: 'ID of the ContainerRepository.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
