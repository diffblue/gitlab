# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class SnippetRepositoryRegistryType < BaseObject
      graphql_name 'SnippetRepositoryRegistry'
      description 'Represents the Geo sync and verification state of a snippet repository'

      include ::Types::Geo::RegistryType

      field :snippet_repository_id, GraphQL::Types::ID, null: false, description: 'ID of the Snippet Repository.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
