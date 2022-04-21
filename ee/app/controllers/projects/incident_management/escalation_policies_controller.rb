# frozen_string_literal: true

module Projects
  module IncidentManagement
    class EscalationPoliciesController < Projects::ApplicationController
      before_action :authorize_read_incident_management_escalation_policy!

      feature_category :incident_management
      urgency :low

      def index
      end
    end
  end
end
