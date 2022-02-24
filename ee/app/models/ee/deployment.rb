# frozen_string_literal: true

module EE
  # Project EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `Deployment` model
  module Deployment
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include UsageStatistics

      delegate :needs_approval?, to: :environment

      has_many :approvals, class_name: 'Deployments::Approval'

      state_machine :status do
        after_transition any => :success do |deployment|
          deployment.run_after_commit do
            # Schedule to refresh the DORA daily metrics.
            # It has 5 minutes delay due to waiting for the other async processes
            # (e.g. `LinkMergeRequestWorker`) to be finished before collecting metrics.
            ::Dora::DailyMetrics::RefreshWorker
              .perform_in(5.minutes,
                          deployment.environment_id,
                          Time.current.to_date.to_s)
          end
        end
      end
    end

    def pending_approval_count
      return 0 unless blocked?

      environment.required_approval_count - approvals.length
    end
  end
end
