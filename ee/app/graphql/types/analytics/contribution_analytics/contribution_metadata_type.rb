# frozen_string_literal: true

module Types
  module Analytics
    module ContributionAnalytics
      # rubocop: disable Graphql/AuthorizeTypes
      class ContributionMetadataType < BaseObject
        graphql_name 'ContributionAnalyticsContribution'
        description 'Represents the contributions of a user.'

        field :issues_closed, GraphQL::Types::Int, null: true,
                                                   description: 'Number of issues closed by the user.'
        field :issues_created, GraphQL::Types::Int, null: true,
                                                    description: 'Number of issues created by the user.'
        field :merge_requests_approved,
          GraphQL::Types::Int, null: true, description: 'Number of merge requests approved by the user.'
        field :merge_requests_closed, GraphQL::Types::Int, null: true,
                                                           description: 'Number of merge requests closed by the user.'
        field :merge_requests_created, GraphQL::Types::Int, null: true,
                                                            description: 'Number of merge requests created by the user.'
        field :merge_requests_merged, GraphQL::Types::Int, null: true,
                                                           description: 'Number of merge requests merged by the user.'
        field :repo_pushed, GraphQL::Types::Int, null: true,
                                                 method: :push,
                                                 description: 'Number of repository pushes the user made.'
        field :total_events, GraphQL::Types::Int, null: true,
                                                  description: 'Total number of events contributed by the user.'
        field :user, ::Types::UserType, null: true,
                                        description: 'Contributor User object.'
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
