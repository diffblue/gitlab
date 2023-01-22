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
      field :created_at, Types::TimeType, null: false, description: 'Timestamp of when the suggestions were created.'
      field :suggested, [GraphQL::Types::String], null: false, description: 'List of suggested reviewer usernames.'
      field :updated_at, Types::TimeType, null: false, description: 'Timestamp of when the suggestions were updated.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
