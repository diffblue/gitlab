# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class LicenseManagementJobsMetric < DatabaseMetric
          operation :count

          relation { ::Ci::Build.license_management_jobs }
        end
      end
    end
  end
end
