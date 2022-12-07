# frozen_string_literal: true

module EE
  module IncidentManagement
    module Escalatable
      extend ActiveSupport::Concern

      MAX_ESCALATION_DELAY = 24.hours

      def escalation_policy
        project.incident_management_escalation_policies.first
      end

      def pending_escalation_target
        self
      end
    end
  end
end
