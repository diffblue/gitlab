# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class ProtectedEnvironmentsRequiredApprovalsAverageMetric < DatabaseMetric
          operation :average, column: :required_approval_count

          relation do
            ProtectedEnvironment.where(required_approval_count: 1..)
          end
        end
      end
    end
  end
end
