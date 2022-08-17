# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class VulnerableDependencyType < BaseObject
    graphql_name 'VulnerableDependency'
    description 'Represents a vulnerable dependency. Used in vulnerability location data'

    field :package, ::Types::VulnerablePackageType,
      null: true, description: 'Package associated with the vulnerable dependency.'

    field :version, GraphQL::Types::String,
      null: true, description: 'Version of the vulnerable dependency.'
  end
end
