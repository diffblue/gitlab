# frozen_string_literal: true

module Groups
  module Security
    class ComplianceViolationReportsController < Groups::ApplicationController
      include Groups::SecurityFeaturesHelper

      before_action :authorize_compliance_dashboard!

      feature_category :compliance_management

      def index
        if feature_enabled?
          ComplianceManagement::Violations::ExportService.new(
            user: current_user,
            namespace: group,
            filters: filter_params,
            sort: sort_param
          ).email_export

          flash[:notice] = _('An email will be sent with the report attached after it is generated.')
        end

        redirect_to group_security_compliance_dashboard_path(group, vueroute: :violations)
      end

      private

      def feature_enabled?
        Feature.enabled?(:compliance_violation_csv_export, group)
      end

      def filter_params
        params.permit(
          :merged_after,
          :merged_before,
          :project_ids,
          :target_branch
        )
      end

      def sort_param
        params.permit(:sort)
      end
    end
  end
end
