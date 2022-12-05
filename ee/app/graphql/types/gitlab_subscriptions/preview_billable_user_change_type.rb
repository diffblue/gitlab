# frozen_string_literal: true

module Types
  module GitlabSubscriptions
    # rubocop:disable Graphql/AuthorizeTypes
    class PreviewBillableUserChangeType < BaseObject
      field :new_billable_user_count, GraphQL::Types::Int, null: true,
                                                           description: 'Total number of billable users after change.'
      field :seats_in_subscription, GraphQL::Types::Int, null: true, description: 'Number of seats in subscription.'
      field :will_increase_overage, GraphQL::Types::Boolean,
       null: true, description: ' If the group will have an increased overage after change.'
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
