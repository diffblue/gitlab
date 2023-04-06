# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class ProjectWikiRepositoryRegistryType < BaseObject
      graphql_name 'ProjectWikiRepositoryRegistry'

      include ::Types::Geo::RegistryType

      description 'Represents the Geo replication and verification state of a project_wiki_repository'

      field :project_wiki_repository_id,
        GraphQL::Types::ID,
        null: false,
        description: 'ID of the Project Wiki Repository.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
