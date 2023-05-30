# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class SecurityPolicyValidationError < BaseObject
    graphql_name 'SecurityPolicyValidationError'
    description 'Security policy validation error'

    field :field, GraphQL::Types::String, null: false, description: 'Error field.'
    field :level, GraphQL::Types::String, null: false, description: 'Error level.'
    field :message, GraphQL::Types::String, null: false, description: 'Error message.'
    field :title, GraphQL::Types::String, null: true, description: 'Error title.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
