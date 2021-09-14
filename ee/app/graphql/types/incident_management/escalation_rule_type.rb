# frozen_string_literal: true

module Types
  module IncidentManagement
    # rubocop: disable Graphql/AuthorizeTypes
    class EscalationRuleType < BaseObject
      graphql_name 'EscalationRuleType'
      description 'Represents an escalation rule for an escalation policy'

      field :id, Types::GlobalIDType[::IncidentManagement::EscalationRule],
            null: true,
            description: 'ID of the escalation policy.'

      field :oncall_schedule, Types::IncidentManagement::OncallScheduleType,
            null: true,
            description: 'On-call schedule to notify.'

      field :user, Types::UserType,
            null: true,
            description: 'User to notify.'

      field :elapsed_time_seconds, GraphQL::Types::Int,
            null: true,
            description: 'Time in seconds before the rule is activated.'

      field :status, Types::IncidentManagement::EscalationRuleStatusEnum,
            null: true,
            description: 'Status required to prevent the rule from activating.'

      def oncall_schedule
        Gitlab::Graphql::Loaders::BatchModelLoader.new(::IncidentManagement::OncallSchedule, object.oncall_schedule_id).find
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
