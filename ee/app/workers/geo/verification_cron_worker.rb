# frozen_string_literal: true

module Geo
  # Calls trigger_background_verification on every enabled Replicator class,
  # every minute.
  #
  class VerificationCronWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include ::Gitlab::Geo::LogHelpers

    # This worker does not perform work scoped to a context
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    idempotent!

    feature_category :geo_replication
    tags :exclude_from_kubernetes, :exclude_from_gitlab_com

    def perform
      Gitlab::Geo.verification_enabled_replicator_classes.each do |replicator_class|
        replicator_class.trigger_background_verification
      end
    end
  end
end
