# frozen_string_literal: true

module IncidentManagement
  module EscalationPolicies
    class CreateService < EscalationPolicies::BaseService
      # @param [Project] project
      # @param [User] current_user
      # @param [Hash] params
      # @option params [String] name
      # @option params [String] description
      # @option params [Array<Hash>] rules_attributes
      # @option params[:rules_attributes] [IncidentManagement::OncallSchedule] oncall_schedule
      # @option params[:rules_attributes] [Integer] elapsed_time_seconds
      # @option params[:rules_attributes] [String] status
      def initialize(project, current_user, params)
        super(project: project, current_user: current_user, params: params)
      end

      def execute
        return error_no_permissions unless allowed?
        return error_no_rules if params[:rules_attributes].blank?
        return error_too_many_rules if too_many_rules?
        return error_bad_schedules if invalid_schedules?
        return error_user_without_permission if users_without_permissions?

        escalation_policy = project.incident_management_escalation_policies.create(params)

        return error_in_save(escalation_policy) unless escalation_policy.persisted?

        success(escalation_policy)
      end
    end
  end
end
