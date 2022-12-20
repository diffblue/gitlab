# frozen_string_literal: true

module Types
  module AppliedMl
    # SuggestedReviewersType have their authorization enforced by MergeRequestType
    # rubocop: disable Graphql/AuthorizeTypes
    class SuggestedReviewersType < BaseObject
      graphql_name 'SuggestedReviewersType'
      description 'Represents a Suggested Reviewers result set'

      present_using ::AppliedMl::SuggestedReviewersPresenter

      field :accepted, [GraphQL::Types::String], null: true, description: 'List of accepted reviewer usernames.'
      field :suggested, [GraphQL::Types::String], null: false, description: 'List of suggested reviewer usernames.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
