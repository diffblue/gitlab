# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class PackageFileRegistryType < BaseObject
      graphql_name 'PackageFileRegistry'
      description 'Represents the Geo sync and verification state of a package file'

      include ::Types::Geo::RegistryType

      field :package_file_id, GraphQL::Types::ID, null: false, description: 'ID of the PackageFile.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
