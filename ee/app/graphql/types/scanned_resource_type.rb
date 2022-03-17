# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class ScannedResourceType < BaseObject
    graphql_name 'ScannedResource'
    description 'Represents a resource scanned by a security scan'

    field :request_method, GraphQL::Types::String, null: true, description: 'HTTP request method used to access the URL.'
    field :url, GraphQL::Types::String, null: true, description: 'URL scanned by the scanner.'
  end
end
