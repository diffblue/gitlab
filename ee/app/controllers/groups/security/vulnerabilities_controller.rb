# frozen_string_literal: true

module Groups
  module Security
    class VulnerabilitiesController < Groups::ApplicationController
      layout 'group'

      feature_category :vulnerability_management
      urgency :low

      def index
        render :unavailable unless dashboard_available?
      end

      private

      def dashboard_available?
        can?(current_user, :read_group_security_dashboard, group)
      end
    end
  end
end
