# frozen_string_literal: true

class ClearSharedRunnersMinutesWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  # all queries are scoped across multiple namespaces
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext
  feature_category :continuous_integration

  def perform; end
end
