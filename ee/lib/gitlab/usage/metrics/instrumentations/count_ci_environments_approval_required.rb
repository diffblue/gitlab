# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountCiEnvironmentsApprovalRequired < DatabaseMetric
          operation :distinct_count, column: :protected_environment_id

          relation { ProtectedEnvironments::ApprovalRule.all }
        end
      end
    end
  end
end
