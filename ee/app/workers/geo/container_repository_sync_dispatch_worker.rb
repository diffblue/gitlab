# frozen_string_literal: true

module Geo
  class ContainerRepositorySyncDispatchWorker < Geo::Scheduler::Secondary::SchedulerWorker # rubocop:disable Scalability/IdempotentWorker
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    def perform
      # no-op The worker is removed. This placeholder worker has to be removed in 16.0
    end
  end
end
