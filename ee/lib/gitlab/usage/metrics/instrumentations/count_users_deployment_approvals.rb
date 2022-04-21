# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUsersDeploymentApprovals < DatabaseMetric
          operation :distinct_count, column: :user_id

          relation { ::Deployments::Approval }
        end
      end
    end
  end
end
