# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class DependencyProxyBlobRegistryType < BaseObject
      graphql_name 'DependencyProxyBlobRegistry'

      include ::Types::Geo::RegistryType

      description 'Represents the Geo replication and verification state of a dependency_proxy_blob'

      field :dependency_proxy_blob_id, GraphQL::Types::ID, null: false, description: 'ID of the Dependency Proxy Blob.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
