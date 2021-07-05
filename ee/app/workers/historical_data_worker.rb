# frozen_string_literal: true

class HistoricalDataWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :utilization

  def perform
    return if License.current.nil? || License.current.trial?

    HistoricalData.track!
  end
end
