# frozen_string_literal: true

module ComplianceManagement
  module Standards
    module Gitlab
      class AtLeastTwoApprovalsService < BaseService
        CHECK_NAME = :at_least_two_approvals

        private

        def status
          project.approval_rules.sum(&:approvals_required) >= 2 ? :success : :fail
        end
      end
    end
  end
end
