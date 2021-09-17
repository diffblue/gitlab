# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class UploadRegistryType < BaseObject
      include ::Types::Geo::RegistryType

      graphql_name 'UploadRegistry'
      description 'Represents the Geo replication and verification state of an upload.'

      field :file_id, GraphQL::Types::ID, null: false, description: 'ID of the Upload.'
    end
  end
end
