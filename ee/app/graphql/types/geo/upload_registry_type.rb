# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class UploadRegistryType < BaseObject
      graphql_name 'UploadRegistry'
      description 'Represents the Geo replication and verification state of an upload.'

      include ::Types::Geo::RegistryType

      field :file_id, GraphQL::Types::ID, null: false, description: 'ID of the Upload.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
