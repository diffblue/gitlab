# frozen_string_literal: true

module Analytics
  module MergeRequestMetricsRefresh
    def initialize(*merge_requests)
      @merge_requests = merge_requests
    end

    def execute(force: false)
      merge_requests.each do |mr|
        mr.ensure_metrics
        mr.reset # clear already loaded (nil) metrics association
        metrics = mr.metrics

        next if !force && metric_already_present?(metrics)

        update_metric!(metrics)
      end
    end

    def execute_async(**kwargs)
      merge_requests.each do |mr|
        CodeReviewMetricsWorker.perform_async(self.class.name, mr.id, **kwargs)
      end
    end

    private

    attr_reader :merge_requests

    def metric_already_present?(metrics)
      raise NotImplementedError
    end

    def update_metric!(metrics)
      raise NotImplementedError
    end
  end
end
