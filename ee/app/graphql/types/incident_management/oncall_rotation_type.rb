# frozen_string_literal: true

module Types
  module IncidentManagement
    class OncallRotationType < BaseObject
      MAX_SHIFTS_FOR_TIMEFRAME = 350

      graphql_name 'IncidentManagementOncallRotation'
      description 'Describes an incident management on-call rotation'

      authorize :read_incident_management_oncall_schedule

      field :id,
            Types::GlobalIDType[::IncidentManagement::OncallRotation],
            null: false,
            description: 'ID of the on-call rotation.'

      field :name,
            GraphQL::Types::String,
            null: false,
            description: 'Name of the on-call rotation.'

      field :starts_at,
            Types::TimeType,
            null: true,
            description: 'Start date of the on-call rotation.'

      field :ends_at,
            Types::TimeType,
            null: true,
            description: 'End date and time of the on-call rotation.'

      field :length,
            GraphQL::Types::Int,
            null: true,
            description: 'Length of the on-call schedule, in the units specified by lengthUnit.'

      field :length_unit,
            Types::IncidentManagement::OncallRotationLengthUnitEnum,
            null: true,
            description: 'Unit of the on-call rotation length.'

      field :active_period,
            Types::IncidentManagement::OncallRotationActivePeriodType,
            null: true,
            description: 'Active period for the on-call rotation.'

      field :participants,
            ::Types::IncidentManagement::OncallParticipantType.connection_type,
            null: true,
            description: 'Participants of the on-call rotation.'

      field :shifts,
            ::Types::IncidentManagement::OncallShiftType.connection_type,
            null: true,
            description: 'Blocks of time for which a participant is on-call within a given time frame. Time frame cannot exceed one month.',
            max_page_size: MAX_SHIFTS_FOR_TIMEFRAME,
            resolver: ::Resolvers::IncidentManagement::OncallShiftsResolver

      def participants
        object.active_participants
      end
    end
  end
end
