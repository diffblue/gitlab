# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class ProjectRepositoryRegistryType < BaseObject
      graphql_name 'ProjectRepositoryRegistry'

      include ::Types::Geo::RegistryType

      description 'Represents the Geo replication and verification state of a project repository'

      field :project_id, GraphQL::Types::ID, null: false, description: 'ID of the Project.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
