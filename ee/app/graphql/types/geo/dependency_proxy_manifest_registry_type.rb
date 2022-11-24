# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class DependencyProxyManifestRegistryType < BaseObject
      graphql_name 'DependencyProxyManifestRegistry'

      include ::Types::Geo::RegistryType

      description 'Represents the Geo replication and verification state of a dependency_proxy_manifest'

      field :dependency_proxy_manifest_id,
        GraphQL::Types::ID,
        null: false,
        description: 'ID of the Dependency Proxy Manifest.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
