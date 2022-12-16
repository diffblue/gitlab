# frozen_string_literal: true

module GitlabSubscriptions
  class NotifySeatsExceededBatchWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    data_consistency :sticky
    worker_has_external_dependencies!

    feature_category :purchase

    def perform
      GitlabSubscriptions::NotifySeatsExceededBatchService.execute
    end
  end
end
