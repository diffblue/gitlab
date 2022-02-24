# frozen_string_literal: true

module Types
  module RequirementsManagement
    # rubocop: disable Graphql/AuthorizeTypes
    class RequirementStatesCountType < BaseObject
      graphql_name 'RequirementStatesCount'
      description 'Counts of requirements by their state'

      field :archived, GraphQL::Types::Int, null: true, description: 'Number of archived requirements.'
      field :opened, GraphQL::Types::Int, null: true, description: 'Number of opened requirements.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
