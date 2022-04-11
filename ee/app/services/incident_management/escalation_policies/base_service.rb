# frozen_string_literal: true

module IncidentManagement
  module EscalationPolicies
    class BaseService < ::BaseProjectService
      MAX_RULE_COUNT = 10

      def allowed?
        current_user&.can?(:admin_incident_management_escalation_policy, project)
      end

      def too_many_rules?
        params[:rules_attributes] && params[:rules_attributes].size > MAX_RULE_COUNT
      end

      def invalid_schedules?
        params[:rules_attributes]&.any? { |attrs| attrs[:oncall_schedule] && attrs[:oncall_schedule].project != project }
      end

      def users_without_permissions?
        DeclarativePolicy.subject_scope do
          params[:rules_attributes]&.any? { |attrs| attrs[:user] && !attrs[:user].can?(:read_project, project) }
        end
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def success(escalation_policy)
        ServiceResponse.success(payload: { escalation_policy: escalation_policy })
      end

      def error_no_permissions
        error(_('You have insufficient permissions to configure escalation policies for this project'))
      end

      def error_no_rules
        error(_('Escalation policies must have at least one rule'))
      end

      def error_too_many_rules
        error(_('Escalation policies may not have more than %{rule_count} rules') % { rule_count: MAX_RULE_COUNT })
      end

      def error_bad_schedules
        error(_('Schedule-based escalation rules must have a schedule in the same project as the policy'))
      end

      def error_user_without_permission
        error(_('User-based escalation rules must have a user with access to the project'))
      end

      def error_in_save(policy)
        error(policy.errors.full_messages.to_sentence)
      end
    end
  end
end
