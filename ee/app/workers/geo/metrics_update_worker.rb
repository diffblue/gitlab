# frozen_string_literal: true

module Geo
  class MetricsUpdateWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    include ExclusiveLeaseGuard
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

    def log_error(message, extra_args = {})
      args = { class: self.class.name, message: message }.merge(extra_args)
      Gitlab::Geo::Logger.error(args)
    end
  end
end
