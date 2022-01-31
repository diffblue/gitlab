# frozen_string_literal: true

module Gitlab
  module ComplianceManagement
    module Violations
      class ApprovedByMergeRequestAuthor
        REASON = :approved_by_merge_request_author
        SEVERITY_LEVEL = :high

        def initialize(merge_request)
          @merge_request = merge_request
        end

        def execute
          if violation?
            @merge_request.compliance_violations.create(
              violating_user: @merge_request.author,
              reason: REASON,
              severity_level: SEVERITY_LEVEL
            )
          end
        end

        private

        def violation?
          @merge_request.approved_by_users.include?(@merge_request.author)
        end
      end
    end
  end
end
