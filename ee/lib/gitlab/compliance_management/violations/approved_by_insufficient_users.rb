# frozen_string_literal: true

module Gitlab
  module ComplianceManagement
    module Violations
      class ApprovedByInsufficientUsers
        REASON = :approved_by_insufficient_users
        SEVERITY_LEVEL = :high

        # The minimum number of approvers is defined by GitLab in our public documentation.
        # https://docs.gitlab.com/ee/user/compliance/compliance_dashboard/#separation-of-duties
        MINIMUM_NUMBER_OF_APPROVERS = 2

        def initialize(merge_request)
          @merge_request = merge_request
        end

        def execute
          if violation?
            @merge_request.compliance_violations.create(
              violating_user: @merge_request.metrics&.merged_by || @merge_request.merge_user,
              reason: REASON,
              severity_level: SEVERITY_LEVEL,
              merged_at: @merge_request.merged_at,
              target_project_id: @merge_request.target_project_id,
              title: @merge_request.title,
              target_branch: @merge_request.target_branch
            )
          end
        end

        private

        def violation?
          @merge_request.approved_by_users.count < MINIMUM_NUMBER_OF_APPROVERS
        end
      end
    end
  end
end
