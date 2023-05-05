# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountUserPreferencesGroupOverviewSecurityDashboardMetric < DatabaseMetric
          operation :count

          relation do
            ::User.active.group_view_security_dashboard
          end
        end
      end
    end
  end
end
