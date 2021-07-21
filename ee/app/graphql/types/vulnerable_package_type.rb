# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class VulnerablePackageType < BaseObject
    graphql_name 'VulnerablePackage'
    description 'Represents a vulnerable package. Used in vulnerability dependency data'

    field :name, GraphQL::Types::String, null: true,
          description: 'The name of the vulnerable package.'
  end
end
