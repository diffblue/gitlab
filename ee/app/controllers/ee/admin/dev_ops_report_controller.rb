# frozen_string_literal: true

module EE
  module Admin
    module DevOpsReportController
      extend ActiveSupport::Concern
      prepended do
        track_event :show,
          name: 'i_analytics_dev_ops_adoption',
          action: 'perform_analytics_usage_action',
          label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
          destinations: %i[redis_hll snowplow],
          conditions: -> { show_adoption? && params[:tab] != 'devops-score' }
      end

      def should_track_devops_score?
        !show_adoption? || params[:tab] == 'devops-score'
      end

      def show_adoption?
        ::License.feature_available?(:devops_adoption)
      end
    end
  end
end
