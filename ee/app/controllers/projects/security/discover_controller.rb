# frozen_string_literal: true

module Projects
  module Security
    class DiscoverController < Projects::ApplicationController
      include SecurityAndCompliancePermissions

      feature_category :activation
      urgency :low

      def show
        render_404 unless helpers.show_discover_project_security?(@project)
      end
    end
  end
end
