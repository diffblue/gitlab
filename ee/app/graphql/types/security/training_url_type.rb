# frozen_string_literal: true

module Types
  module Security
    class TrainingUrlType < BaseObject # rubocop:disable Graphql/AuthorizeTypes (This can be only accessed through VulnerabilityType)
      graphql_name 'SecurityTrainingUrl'
      description 'Represents a URL related to a security training'

      field :status, Types::Security::TrainingUrlRequestStatusEnum, null: true,
              description: 'Status of the request to training provider.'

      field :name, GraphQL::Types::String, null: true,
            description: 'Name of the training provider.'

      field :url, GraphQL::Types::String, null: true,
            description: 'URL of the link for security training content.'
    end
  end
end
