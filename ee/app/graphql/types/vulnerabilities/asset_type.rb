# frozen_string_literal: true

module Types
  module Vulnerabilities
    # rubocop: disable Graphql/AuthorizeTypes
    class AssetType < BaseObject
      graphql_name 'AssetType'
      description 'Represents a vulnerability asset type.'

      field :name, GraphQL::Types::String,
        null: false, description: 'Name of the asset.'

      field :type, GraphQL::Types::String,
        null: false, description: 'Type of the asset.'

      field :url, GraphQL::Types::String,
        null: false, description: 'URL of the asset.'
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
