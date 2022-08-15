# frozen_string_literal: true

module Types
  module Dast
    class ProfileScheduleType < BaseObject
      graphql_name 'DastProfileSchedule'
      description 'Represents a DAST profile schedule.'

      authorize :read_on_demand_dast_scan

      field :id, ::Types::GlobalIDType[::Dast::ProfileSchedule],
        null: false, description: 'ID of the DAST profile schedule.'

      field :active, GraphQL::Types::Boolean,
        null: true, description: 'Status of the DAST profile schedule.'

      field :starts_at, Types::TimeType,
        null: true, description: 'Start time of the DAST profile schedule in the given timezone.'

      field :timezone, GraphQL::Types::String,
        null: true, description: 'Time zone of the start time of the DAST profile schedule.'

      field :cadence, Types::Dast::ProfileCadenceType,
        null: true, description: 'Cadence of the DAST profile schedule.'

      field :next_run_at, Types::TimeType,
        null: true, description: 'Next run time of the DAST profile schedule in the given timezone.'

      field :owner_valid, GraphQL::Types::Boolean,
        null: true, description: 'Status of the current owner of the DAST profile schedule.', method: :owner_valid?

      def starts_at
        return unless object.starts_at && object.timezone

        object.starts_at.in_time_zone(object.timezone)
      end

      def next_run_at
        return unless object.next_run_at && object.timezone

        object.next_run_at.in_time_zone(object.timezone)
      end
    end
  end
end
