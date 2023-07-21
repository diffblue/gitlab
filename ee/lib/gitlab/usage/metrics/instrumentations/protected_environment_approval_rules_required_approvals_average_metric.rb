# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ProtectedEnvironmentApprovalRulesRequiredApprovalsAverageMetric < DatabaseMetric
          operation :average, column: :required_approvals

          relation do
            ProtectedEnvironments::ApprovalRule.where(required_approvals: 1..)
          end
        end
      end
    end
  end
end
