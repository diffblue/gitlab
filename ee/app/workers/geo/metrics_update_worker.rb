# frozen_string_literal: true

module Geo
  class MetricsUpdateWorker
    include ApplicationWorker

    idempotent!
    data_consistency :always
    deduplicate :until_executed, ttl: 20.minutes

    include Gitlab::Geo::LogHelpers
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :geo_replication

    def perform
      Geo::MetricsUpdateService.new.execute
    end
  end
end
