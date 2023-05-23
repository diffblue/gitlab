# frozen_string_literal: true

module EE
  module MergeRequests
    module ReopenService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(merge_request)
        super.tap do
          if current_user.project_bot?
            log_audit_event(merge_request, 'merge_request_reopened_by_project_bot',
              "Reopened merge request #{merge_request.title}")
          end
        end
      end
    end
  end
end
