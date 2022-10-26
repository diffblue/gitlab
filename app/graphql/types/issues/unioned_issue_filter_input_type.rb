# frozen_string_literal: true

module Types
  module Issues
    class UnionedIssueFilterInputType < BaseInputObject
      graphql_name 'UnionedIssueFilterInput'

      argument :assignee_usernames, [GraphQL::Types::String],
               required: false,
               description: 'Filters issues that are assigned to at least one of the given usernames.'
      argument :author_usernames, [GraphQL::Types::String],
               required: false,
               description: 'Filters issues that are authored by one of the given usernames.'
    end
  end
end
