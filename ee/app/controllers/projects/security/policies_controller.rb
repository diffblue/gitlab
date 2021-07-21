# frozen_string_literal: true

module Projects
  module Security
    class PoliciesController < Projects::ApplicationController
      include SecurityAndCompliancePermissions

      before_action :authorize_security_orchestration_policies!

      before_action do
        push_frontend_feature_flag(:security_orchestration_policies_configuration, project)
        check_feature_flag!
      end

      feature_category :security_orchestration

      def show
        render :show, locals: { project: project }
      end

      private

      def check_feature_flag!
        render_404 if Feature.disabled?(:security_orchestration_policies_configuration, project)
      end
    end
  end
end
