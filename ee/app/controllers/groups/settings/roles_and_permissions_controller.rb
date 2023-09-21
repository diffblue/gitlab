# frozen_string_literal: true

module Groups
  module Settings
    class RolesAndPermissionsController < Groups::ApplicationController
      feature_category :user_management

      before_action :authorize_admin_member_roles!
      before_action :ensure_root_group!
      before_action :ensure_custom_roles_available!

      private

      def authorize_admin_member_roles!
        render_404 unless current_user.can?(:admin_group_member, group)
      end

      def ensure_root_group!
        render_404 unless group.root?
      end

      def ensure_custom_roles_available!
        render_404 unless Feature.enabled?(:custom_roles_ui_saas, group) &&
          group.licensed_feature_available?(:custom_roles)
      end
    end
  end
end
