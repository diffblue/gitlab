# frozen_string_literal: true

module Types
  module Vulnerabilities
    # rubocop: disable Graphql/AuthorizeTypes
    class RemediationType < BaseObject
      graphql_name 'VulnerabilityRemediationType'
      description 'Represents a vulnerability remediation type.'

      field :summary,
        GraphQL::Types::String,
        null: true,
        description: 'Summary of the remediation.'

      field :diff,
        GraphQL::Types::String,
        null: true,
        description: 'Diff of the remediation.'
    end
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
