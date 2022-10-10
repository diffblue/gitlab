# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectsWithAssignedSecurityPolicyProjectMetric < DatabaseMetric
          operation :distinct_count, column: :project_id

          relation { ::Security::OrchestrationPolicyConfiguration }

          start { ::Security::OrchestrationPolicyConfiguration.minimum(:project_id) }
          finish { ::Security::OrchestrationPolicyConfiguration.maximum(:project_id) }
        end
      end
    end
  end
end
