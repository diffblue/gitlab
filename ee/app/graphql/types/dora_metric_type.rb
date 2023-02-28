# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class DoraMetricType < BaseObject
    graphql_name 'DoraMetric'

    field :date, GraphQL::Types::String, null: true, description: 'Date of the data point.'

    field :value, GraphQL::Types::Float, null: true,
      description: 'Value of the data point.',
      deprecated: { reason: 'Moved to corresponding metric field', milestone: '15.10' }

    field :deployment_frequency, GraphQL::Types::Float, null: true,
      description: 'Number of deployments per day.'

    field :lead_time_for_changes, GraphQL::Types::Float, null: true,
      description: 'Median time to deploy a merged merge request.'

    field :time_to_restore_service, GraphQL::Types::Float, null: true,
      description: 'Median time to close an incident.'

    field :change_failure_rate, GraphQL::Types::Float, null: true,
      description: 'Percentage of deployments that caused incidents in production.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
