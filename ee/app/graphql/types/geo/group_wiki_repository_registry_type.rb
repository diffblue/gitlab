# frozen_string_literal: true

module Types
  module Geo
    # rubocop:disable Graphql/AuthorizeTypes because it is included
    class GroupWikiRepositoryRegistryType < BaseObject
      graphql_name 'GroupWikiRepositoryRegistry'
      description 'Represents the Geo sync and verification state of a group wiki repository'

      include ::Types::Geo::RegistryType

      field :group_wiki_repository_id, GraphQL::Types::ID, null: false, description: 'ID of the Group Wiki Repository.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
