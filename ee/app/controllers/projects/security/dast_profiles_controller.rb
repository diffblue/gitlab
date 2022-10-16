# frozen_string_literal: true

module Projects
  module Security
    class DastProfilesController < Projects::ApplicationController
      include SecurityAndCompliancePermissions

      before_action do
        authorize_read_on_demand_dast_scan!
      end

      feature_category :dynamic_application_security_testing
      urgency :low

      def show
      end
    end
  end
end
