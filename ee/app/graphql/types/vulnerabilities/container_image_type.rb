# frozen_string_literal: true

module Types
  module Vulnerabilities
    # rubocop: disable Graphql/AuthorizeTypes
    class ContainerImageType < BaseObject
      graphql_name 'VulnerabilityContainerImage'
      description 'Represents a container image reported on the related vulnerability'

      field :name, GraphQL::Types::String,
        null: true, method: :location_image, description: 'Name of the container image.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
