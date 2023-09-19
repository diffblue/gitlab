# frozen_string_literal: true

module ComplianceManagement
  module Standards
    module Gitlab
      class AtLeastTwoApprovalsService < BaseService
        CHECK_NAME = :at_least_two_approvals

        private

        def status
          total_required_approvals = project.approval_rules.pick("SUM(approvals_required)") || 0
          total_required_approvals >= 2 ? :success : :fail
        end
      end
    end
  end
end
