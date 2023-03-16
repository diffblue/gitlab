# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class CiSecureFileRegistryType < BaseObject
      graphql_name 'CiSecureFileRegistry'
      description 'Represents the Geo replication and verification state of a ci_secure_file.'

      include ::Types::Geo::RegistryType

      field :ci_secure_file_id, GraphQL::Types::ID, null: false, description: 'ID of the Ci Secure File.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
