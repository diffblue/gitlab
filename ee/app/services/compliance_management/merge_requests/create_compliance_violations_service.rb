# frozen_string_literal: true

module ComplianceManagement
  module MergeRequests
    class CreateComplianceViolationsService < ComplianceManagement::MergeRequests::BaseService
      def execute
        return ServiceResponse.error(message: _('This group is not permitted to create compliance violations')) unless permitted?(@merge_request.target_project.namespace)
        return ServiceResponse.error(message: _('Merge request not merged')) unless @merge_request.merged?

        ::MergeRequests::ComplianceViolation.process_merge_request(@merge_request)

        ServiceResponse.success(message: _('Created compliance violations if any were found'))
      end

      private

      def permitted?(group)
        group.licensed_feature_available?(:group_level_compliance_dashboard)
      end
    end
  end
end
