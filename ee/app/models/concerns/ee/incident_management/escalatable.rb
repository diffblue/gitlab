# frozen_string_literal: true

module EE
  module IncidentManagement
    module Escalatable
      extend ActiveSupport::Concern

      def escalation_policy
        project.incident_management_escalation_policies.first
      end
    end
  end
end
