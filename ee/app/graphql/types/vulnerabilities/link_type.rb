# frozen_string_literal: true

module Types
  module Vulnerabilities
    class LinkType < BaseObject # rubocop:disable Graphql/AuthorizeTypes(This can be only accessible through vulnerability type)
      graphql_name 'VulnerabilityLink'
      description 'Represents a link related to a vulnerability'

      field :name, GraphQL::Types::String, null: true, description: 'Name of the link.'

      field :url, GraphQL::Types::String, null: false, description: 'URL of the link.'
    end
  end
end
