# frozen_string_literal: true

module Types
  module IncidentManagement
    class EscalationRuleInputType < BaseInputObject
      graphql_name 'EscalationRuleInput'
      description 'Represents an escalation rule'

      argument :oncall_schedule_iid, GraphQL::Types::ID, # rubocop: disable Graphql/IDType
        description: 'On-call schedule to notify.',
        required: false

      argument :username, GraphQL::Types::String,
        description: 'Username of the user to notify.',
        required: false

      argument :elapsed_time_seconds, GraphQL::Types::Int,
        description: 'Time in seconds before the rule is activated.',
        required: true

      argument :status, Types::IncidentManagement::EscalationRuleStatusEnum,
        description: 'Status required to prevent the rule from activating.',
        required: true

      def prepare
        unless schedule_iid_or_username
          raise Gitlab::Graphql::Errors::ArgumentError, 'One of oncall_schedule_iid or username must be provided'
        end

        super
      end

      def schedule_iid_or_username
        oncall_schedule_iid.present? ^ username.present?
      end
    end
  end
end
