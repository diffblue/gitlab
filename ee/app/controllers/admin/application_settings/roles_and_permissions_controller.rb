# frozen_string_literal: true

module Admin
  module ApplicationSettings
    class RolesAndPermissionsController < Admin::ApplicationController
      feature_category :user_management

      before_action :ensure_custom_roles_available!

      private

      def ensure_custom_roles_available!
        render_404 unless Feature.enabled?(:custom_roles_ui_self_managed) && License.feature_available?(:custom_roles)
      end
    end
  end
end
