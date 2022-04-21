# frozen_string_literal: true

module IncidentManagement
  module EscalationPolicies
    class DestroyService < EscalationPolicies::BaseService
      # @param escalation_policy [IncidentManagement::EscalationPolicy]
      # @param current_user [User]
      def initialize(escalation_policy, current_user)
        super(project: escalation_policy.project, current_user: current_user)

        @escalation_policy = escalation_policy
      end

      def execute
        return error_no_permissions unless allowed?

        if escalation_policy.destroy
          success(escalation_policy)
        else
          error_in_save(escalation_policy)
        end
      end

      private

      attr_reader :escalation_policy
    end
  end
end
