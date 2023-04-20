# frozen_string_literal: true

module Geo
  class MetricsUpdateWorker
    include ApplicationWorker

    idempotent!
    data_consistency :always

    include ExclusiveLeaseGuard
    include Gitlab::Geo::LogHelpers
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :geo_replication

    LEASE_TIMEOUT = 1.hour

    def perform
      try_obtain_lease { Geo::MetricsUpdateService.new.execute }
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
