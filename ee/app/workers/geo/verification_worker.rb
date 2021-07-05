# frozen_string_literal: true

module Geo
  class VerificationWorker
    include ApplicationWorker

    data_consistency :always
    include GeoQueue
    include ::Gitlab::Geo::LogHelpers

    sidekiq_options retry: 3, dead: false

    idempotent!
    tags :exclude_from_kubernetes, :exclude_from_gitlab_com
    loggable_arguments 0

    def perform(replicable_name, replicable_id)
      replicator = ::Gitlab::Geo::Replicator.for_replicable_params(replicable_name: replicable_name, replicable_id: replicable_id)

      replicator.verify
    rescue ActiveRecord::RecordNotFound
      log_error("Couldn't find the record, skipping", replicable_name: replicable_name, replicable_id: replicable_id)
    end
  end
end
