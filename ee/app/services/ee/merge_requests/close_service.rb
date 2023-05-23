# frozen_string_literal: true

module EE
  module MergeRequests
    module CloseService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(merge_request, commit = nil)
        super.tap do
          if current_user.project_bot?
            log_audit_event(merge_request, 'merge_request_closed_by_project_bot',
              "Closed merge request #{merge_request.title}")
          end
        end
      end

      def expire_unapproved_key(merge_request)
        merge_request.approval_state.expire_unapproved_key!
      end
    end
  end
end
