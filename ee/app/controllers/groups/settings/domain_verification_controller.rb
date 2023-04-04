# frozen_string_literal: true

module Groups
  module Settings
    class DomainVerificationController < Groups::ApplicationController
      layout 'group_settings'

      before_action :check_feature_availability
      before_action :authorize_admin_group!

      feature_category :system_access
      urgency :low

      def index
        @hide_search_settings = true
        @domains = group.all_projects_pages_domains(only_verified: false)
      end

      private

      def check_feature_availability
        render_404 unless group.domain_verification_available?
      end
    end
  end
end
