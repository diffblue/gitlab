# frozen_string_literal: true

module EE
  module MergeRequests
    module PostMergeService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(merge_request)
        super
        ApprovalRules::FinalizeService.new(merge_request).execute

        if compliance_violations_enabled?(merge_request.target_project.namespace)
          ComplianceManagement::MergeRequests::ComplianceViolationsWorker.perform_async(merge_request.id)
        end
      end

      private

      def compliance_violations_enabled?(group)
        group.licensed_feature_available?(:group_level_compliance_dashboard)
      end
    end
  end
end
