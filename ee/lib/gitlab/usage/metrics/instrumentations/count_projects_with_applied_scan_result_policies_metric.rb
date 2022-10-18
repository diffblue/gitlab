# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectsWithAppliedScanResultPoliciesMetric < DatabaseMetric
          operation :distinct_count, column: :project_id

          relation { ::ApprovalProjectRule.scan_finding }

          start { ::ApprovalProjectRule.minimum(:project_id) }
          finish { ::ApprovalProjectRule.maximum(:project_id) }
        end
      end
    end
  end
end
