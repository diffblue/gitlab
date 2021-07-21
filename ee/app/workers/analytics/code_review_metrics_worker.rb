# frozen_string_literal: true

module Analytics
  class CodeReviewMetricsWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    feature_category :code_analytics
    idempotent!
    loggable_arguments 0

    def perform(operation, merge_request_id, execute_kwargs = {})
      ::MergeRequest.find_by_id(merge_request_id).try do |merge_request|
        break unless merge_request.project.feature_available?(:code_review_analytics)

        operation_klass = operation.constantize
        operation_klass.new(merge_request).execute(**execute_kwargs.deep_symbolize_keys)
      end
    end
  end
end
