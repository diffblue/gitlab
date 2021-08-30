# frozen_string_literal: true

module Geo
  # Calls trigger_background_verification on every enabled Replicator class,
  # every minute.
  #
  class VerificationCronWorker
    include ApplicationWorker

    data_consistency :always

    include ::Gitlab::Geo::LogHelpers

    # This worker does not perform work scoped to a context
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    idempotent!

    feature_category :geo_replication

    def perform
      Gitlab::Geo.verification_enabled_replicator_classes.each do |replicator_class|
        replicator_class.trigger_background_verification
      end
    end
  end
end
