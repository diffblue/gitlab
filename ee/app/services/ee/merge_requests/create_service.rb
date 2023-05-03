# frozen_string_literal: true

module EE
  module MergeRequests
    module CreateService
      extend ::Gitlab::Utils::Override

      override :set_default_attributes!
      def set_default_attributes!
        return unless ::Feature.enabled?(:inherit_approval_rules_on_creation, project)
        return if params[:approval_rules_attributes].present?

        # Pick only regular or any_approver to match frontend behavior:
        # See https://gitlab.com/gitlab-org/gitlab/blob/ea40bc69a9309e0c8691588a920383394ebc649c/ee/app/assets/javascripts/approvals/mappers.js#L80-88
        # See issue: https://gitlab.com/gitlab-org/gitlab/-/issues/408380
        approval_rules_attrs = project.approval_rules.regular_or_any_approver.map(&:to_nested_attributes)

        params[:approval_rules_attributes] = approval_rules_attrs if approval_rules_attrs.present?
      end

      override :after_create
      def after_create(issuable)
        issuable.run_after_commit do
          ::MergeRequests::SyncCodeOwnerApprovalRulesWorker.perform_async(issuable.id)
        end

        super

        ::MergeRequests::SyncReportApproverApprovalRules.new(issuable, current_user).execute

        ::MergeRequests::UpdateBlocksService
          .new(issuable, current_user, blocking_merge_requests_params)
          .execute

        stream_audit_event(issuable)
      end

      private

      def stream_audit_event(merge_request)
        audit_context = {
          name: 'merge_request_create',
          stream_only: true,
          author: current_user,
          scope: merge_request.project,
          target: merge_request,
          message: 'Added merge request'
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
      end
    end
  end
end
