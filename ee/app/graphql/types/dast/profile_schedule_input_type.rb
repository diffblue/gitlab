# frozen_string_literal: true

module Types
  module Dast
    class ProfileScheduleInputType < BaseInputObject
      graphql_name 'DastProfileScheduleInput'
      description 'Input type for DAST Profile Schedules'
      argument :active, GraphQL::Types::Boolean,
            required: false,
            description: 'Status of a Dast Profile Schedule.'

      argument :starts_at, Types::TimeType,
            required: false,
            description: 'Start time of a Dast Profile Schedule.'

      argument :timezone, GraphQL::Types::String,
            required: false,
            description: 'Time Zone for the Start time of a Dast Profile Schedule.'

      argument :cadence, ::Types::Dast::ProfileCadenceInputType,
            required: false,
            description: 'Cadence of a Dast Profile Schedule.'
    end
  end
end
