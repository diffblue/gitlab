# frozen_string_literal: true
# rubocop:disable Graphql/AuthorizeTypes

module Types
  module Analytics
    module DevopsAdoption
      class SnapshotType < BaseObject
        graphql_name 'DevopsAdoptionSnapshot'
        description 'Snapshot'

        field :code_owners_used_count, GraphQL::Types::Int,
          null: true,
          description: 'Total number of projects with existing CODEOWNERS file.'

        field :coverage_fuzzing_enabled_count, GraphQL::Types::Int,
          null: true,
          description: 'Total number of projects with enabled coverage fuzzing.'

        field :dast_enabled_count, GraphQL::Types::Int,
          null: true,
          description: 'Total number of projects with enabled DAST.'

        field :dependency_scanning_enabled_count, GraphQL::Types::Int,
          null: true,
          description: 'Total number of projects with enabled dependency scanning.'

        field :deploy_succeeded, GraphQL::Types::Boolean,
          null: false,
          description: 'At least one deployment succeeded.'

        field :end_time, Types::TimeType,
          null: false,
          description: 'End time for the snapshot where the data points were collected.'

        field :issue_opened, GraphQL::Types::Boolean,
          null: false,
          description: 'At least one issue was opened.'

        field :merge_request_approved, GraphQL::Types::Boolean,
          null: false,
          description: 'At least one merge request was approved.'

        field :merge_request_opened, GraphQL::Types::Boolean,
          null: false,
          description: 'At least one merge request was opened.'

        field :pipeline_succeeded, GraphQL::Types::Boolean,
          null: false,
          description: 'At least one pipeline succeeded.'

        field :recorded_at, Types::TimeType,
          null: false,
          description: 'Time the snapshot was recorded.'

        field :runner_configured, GraphQL::Types::Boolean,
          null: false,
          description: 'At least one runner was used.'

        field :sast_enabled_count, GraphQL::Types::Int,
          null: true,
          description: 'Total number of projects with enabled SAST.'

        field :start_time, Types::TimeType,
          null: false,
          description: 'Start time for the snapshot where the data points were collected.'

        field :total_projects_count, GraphQL::Types::Int,
          null: true,
          description: 'Total number of projects.'

        field :vulnerability_management_used_count, GraphQL::Types::Int,
          null: true,
          description: 'Total number of projects with vulnerability management used at least once.'
      end
    end
  end
end
