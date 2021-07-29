# frozen_string_literal: true

module Geo
  class SidekiqCronConfigWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :geo_replication
    worker_resource_boundary :cpu

    def perform
      Gitlab::Geo::CronManager.new.execute
    end
  end
end
