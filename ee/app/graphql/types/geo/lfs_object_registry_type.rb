# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class LfsObjectRegistryType < BaseObject
      include ::Types::Geo::RegistryType

      graphql_name 'LfsObjectRegistry'
      description 'Represents the Geo sync and verification state of an LFS object'

      field :lfs_object_id, GraphQL::Types::ID, null: false, description: 'ID of the LFS object.'
    end
  end
end
