# frozen_string_literal: true
# rubocop:disable Graphql/AuthorizeTypes

module Types
  module Analytics
    module DevopsAdoption
      class SnapshotType < BaseObject
        graphql_name 'DevopsAdoptionSnapshot'
        description 'Snapshot'

        field :issue_opened, GraphQL::BOOLEAN_TYPE, null: false,
              description: 'At least one issue was opened.'
        field :merge_request_opened, GraphQL::BOOLEAN_TYPE, null: false,
              description: 'At least one merge request was opened.'
        field :merge_request_approved, GraphQL::BOOLEAN_TYPE, null: false,
              description: 'At least one merge request was approved.'
        field :runner_configured, GraphQL::BOOLEAN_TYPE, null: false,
              description: 'At least one runner was used.'
        field :pipeline_succeeded, GraphQL::BOOLEAN_TYPE, null: false,
              description: 'At least one pipeline succeeded.'
        field :deploy_succeeded, GraphQL::BOOLEAN_TYPE, null: false,
              description: 'At least one deployment succeeded.'
        field :security_scan_succeeded, GraphQL::BOOLEAN_TYPE, null: false,
              description: 'At least one security scan succeeded.',
              deprecated: { reason: 'Substituted with specific security metrics. Always false', milestone: '14.1' }
        field :code_owners_used_count, GraphQL::INT_TYPE, null: true,
              description: 'Total number of projects with existing CODEOWNERS file.'
        field :sast_enabled_count, GraphQL::INT_TYPE, null: true,
              description: 'Total number of projects with enabled SAST.'
        field :dast_enabled_count, GraphQL::INT_TYPE, null: true,
              description: 'Total number of projects with enabled DAST.'
        field :dependency_scanning_enabled_count, GraphQL::INT_TYPE, null: true,
              description: 'Total number of projects with enabled dependency scanning.'
        field :coverage_fuzzing_enabled_count, GraphQL::INT_TYPE, null: true,
              description: 'Total number of projects with enabled coverage fuzzing.'
        field :vulnerability_management_used_count, GraphQL::INT_TYPE, null: true,
              description: 'Total number of projects with vulnerability management used at least once.'
        field :total_projects_count, GraphQL::INT_TYPE, null: true,
              description: 'Total number of projects.'
        field :recorded_at, Types::TimeType, null: false,
              description: 'The time the snapshot was recorded.'
        field :start_time, Types::TimeType, null: false,
              description: 'The start time for the snapshot where the data points were collected.'
        field :end_time, Types::TimeType, null: false,
              description: 'The end time for the snapshot where the data points were collected.'
      end
    end
  end
end
