# frozen_string_literal: true

module Geo
  class DestroyWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include GeoQueue
    include ::Gitlab::Geo::LogHelpers

    idempotent!

    tags :exclude_from_kubernetes, :exclude_from_gitlab_com
    loggable_arguments 0

    def perform(replicable_name, replicable_id)
      log_info('Executing Geo::DestroyWorker', replicable_id: replicable_id, replicable_name: replicable_name)

      replicator = ::Gitlab::Geo::Replicator.for_replicable_params(replicable_name: replicable_name, replicable_id: replicable_id)

      replicator.replicate_destroy({})
    end
  end
end
