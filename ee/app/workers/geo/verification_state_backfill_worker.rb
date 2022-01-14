# frozen_string_literal: true

module Geo
  # Iterates over the table corresponding to the `replicable_class`
  # to backfill the corresponding verification state table.
  class VerificationStateBackfillWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    include ::Gitlab::Geo::LogHelpers
    include GeoQueue
    prepend Reenqueuer

    LEASE_TIMEOUT = 30.minutes

    def perform(replicable_name)
      replicator_class = ::Gitlab::Geo::Replicator.for_replicable_name(replicable_name)

      replicator_class.backfill_verification_state_table
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
