# frozen_string_literal: true

module Types
  module IncidentManagement
    class OncallScheduleType < BaseObject
      graphql_name 'IncidentManagementOncallSchedule'
      description 'Describes an incident management on-call schedule'

      authorize :read_incident_management_oncall_schedule

      field :iid,
            GraphQL::Types::ID,
            null: false,
            description: 'Internal ID of the on-call schedule.'

      field :name,
            GraphQL::Types::String,
            null: false,
            description: 'Name of the on-call schedule.'

      field :description,
            GraphQL::Types::String,
            null: true,
            description: 'Description of the on-call schedule.'

      field :timezone,
            GraphQL::Types::String,
            null: false,
            description: 'Time zone of the on-call schedule.'

      field :rotations,
            OncallRotationType.connection_type,
            null: false,
            description: 'On-call rotations for the on-call schedule.'

      field :rotation,
            OncallRotationType,
            null: true,
            description: 'On-call rotation for the on-call schedule.',
            resolver: ::Resolvers::IncidentManagement::OncallRotationsResolver.single
    end
  end
end
