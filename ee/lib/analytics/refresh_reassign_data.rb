# frozen_string_literal: true

module Analytics
  class RefreshReassignData
    include MergeRequestMetricsRefresh

    # Override `MergeRequestMetricsRefresh#initialize` to accept single MR only
    # rubocop:disable Lint/UselessMethodDefinition
    def initialize(merge_request)
      super
    end
    # rubocop:enable Lint/UselessMethodDefinition

    private

    def metric_already_present?(metrics)
      metrics.first_reassigned_at
    end

    def update_metric!(metrics)
      metrics.update!(
        first_reassigned_at: MergeRequestMetricsCalculator.new(metrics.merge_request).first_reassigned_at
      )
    end
  end
end
