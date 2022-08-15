# frozen_string_literal: true

module Types
  module Security
    class TrainingType < BaseObject # rubocop:disable Graphql/AuthorizeTypes(Authorization is done in resolver layer)
      graphql_name 'ProjectSecurityTraining'

      field :id,
        type: ::Types::GlobalIDType, null: false, description: 'ID of the training provider.'

      field :name, GraphQL::Types::String,
        null: false, description: 'Name of the training provider.'

      field :description, GraphQL::Types::String,
        null: true, description: 'Description of the training provider.'

      field :url, GraphQL::Types::String, null: false, description: 'URL of the provider.'

      field :logo_url, GraphQL::Types::String, null: true, description: 'Logo URL of the provider.'

      field :is_enabled, GraphQL::Types::Boolean,
        null: false, description: 'Represents whether the provider is enabled or not.'

      field :is_primary, GraphQL::Types::Boolean,
        null: false, description: 'Represents whether the provider is set as primary or not.'
    end
  end
end
