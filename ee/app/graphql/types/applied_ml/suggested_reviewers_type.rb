# frozen_string_literal: true

module Types
  module AppliedMl
    # SuggestedReviewersType have their authorization enforced by MergeRequestType
    # rubocop: disable Graphql/AuthorizeTypes
    class SuggestedReviewersType < BaseObject
      graphql_name 'SuggestedReviewersType'
      description 'Represents a Suggested Reviewers result set'

      field :reviewers, [GraphQL::Types::String], null: false, description: 'List of reviewers.'
      field :top_n, GraphQL::Types::Int, null: true, description: 'Number of reviewers returned.'
      field :version, GraphQL::Types::String, null: true, description: 'Suggested reviewer version.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
