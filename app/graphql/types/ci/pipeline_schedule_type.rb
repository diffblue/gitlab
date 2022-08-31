# frozen_string_literal: true

module Types
  module Ci
    class PipelineScheduleType < BaseObject
      graphql_name 'PipelineSchedule'

      connection_type_class(Types::CountableConnectionType)

      expose_permissions Types::PermissionTypes::Ci::PipelineSchedules

      authorize :read_pipeline_schedule

      field :id, GraphQL::Types::ID, null: false, description: 'ID of the pipeline schedule.'

      field :description, GraphQL::Types::String, null: true, description: 'Description of the pipeline schedule.'

      field :owner, ::Types::UserType, null: false, description: 'Owner of the pipeline schedule.'

      field :active, GraphQL::Types::Boolean, null: false, description: 'Indicates if a pipeline schedule is active.'

      field :next_run_at, Types::TimeType, null: false, description: 'Time when the next pipeline will run.'

      field :real_next_run, Types::TimeType, null: false, description: 'Time when the next pipeline will run.'

      field :last_pipeline, PipelineType, null: false, description: 'Last pipeline object.'

      field :ref_for_display, GraphQL::Types::String, null: true, description: 'Git ref for the pipeline schedule.'

      field :ref_path, GraphQL::Types::String, null: true, description: 'Path to the ref that triggered the pipeline.'

      field :for_tag, GraphQL::Types::Boolean,
            null: false, description: 'Determines if a pipelines schedule belongs to a tag.'

      field :cron, GraphQL::Types::String, null: false, description: 'Cron notation for the schedule.'

      field :cron_timezone, GraphQL::Types::String, null: false, description: 'Timezone for the pipeline schedule.'

      def ref_for_display
        return unless object.ref.present?

        object.ref.gsub(%r{^refs/(heads|tags)/}, '')
      end

      def ref_path
        ::Gitlab::Routing.url_helpers.project_commits_path(object.project, ref_for_display)
      end

      def for_tag
        return false unless object.ref.present?

        object.ref.start_with? 'refs/tags/'
      end
    end
  end
end
