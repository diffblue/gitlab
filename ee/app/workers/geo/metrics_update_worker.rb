# frozen_string_literal: true

module Geo
  class MetricsUpdateWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include ExclusiveLeaseGuard
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :geo_replication
    tags :exclude_from_gitlab_com

    LEASE_TIMEOUT = 5.minutes

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
