# frozen_string_literal: true

module Projects
  module IncidentManagement
    class OncallSchedulesController < Projects::ApplicationController
      before_action :authorize_read_incident_management_oncall_schedule!

      feature_category :incident_management
      urgency :low

      def index
      end
    end
  end
end
