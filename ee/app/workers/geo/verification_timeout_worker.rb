# frozen_string_literal: true

module Geo
  # Fail verification for records which started verification a long time ago
  class VerificationTimeoutWorker
    include ApplicationWorker
    include GeoQueue
    include ::Gitlab::Geo::LogHelpers

    # Do not execute (in fact, don't even enqueue) another instance of
    # this Worker with the same args.
    deduplicate :until_executed, including_scheduled: true
    idempotent!

    data_consistency :always

    sidekiq_options retry: false
    loggable_arguments 0

    def perform(replicable_name)
      replicator_class_for(replicable_name).fail_verification_timeouts
    end

    def replicator_class_for(replicable_name)
      @replicator_class ||= ::Gitlab::Geo::Replicator.for_replicable_name(replicable_name)
    end
  end
end
