# frozen_string_literal: true

module Geo
  class DestroyWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include GeoQueue
    include ::Gitlab::Geo::LogHelpers

    # Do not execute (in fact, don't even enqueue) another instance of this Worker with the same args
    deduplicate :until_executed, including_scheduled: true
    idempotent!

    loggable_arguments 0

    def perform(replicable_name, replicable_id)
      log_info('Executing Geo::DestroyWorker', replicable_id: replicable_id, replicable_name: replicable_name)

      replicator = ::Gitlab::Geo::Replicator.for_replicable_params(replicable_name: replicable_name, replicable_id: replicable_id)

      replicator.replicate_destroy({})
    end
  end
end
