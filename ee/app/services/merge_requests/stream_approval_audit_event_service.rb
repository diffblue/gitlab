# frozen_string_literal: true

module MergeRequests
  class StreamApprovalAuditEventService < MergeRequests::BaseService
    def execute(merge_request)
      audit_context = {
        name: 'merge_request_approval_operation',
        stream_only: true,
        author: current_user,
        scope: merge_request.project,
        target: merge_request,
        message: 'Approved merge request'
      }

      ::Gitlab::Audit::Auditor.audit(audit_context)
    end
  end
end
