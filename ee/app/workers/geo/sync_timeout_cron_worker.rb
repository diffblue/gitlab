# frozen_string_literal: true

module Geo
  # Fail sync for records which started syncing a long time ago
  class SyncTimeoutCronWorker
    include ApplicationWorker

    data_consistency :always
    include ::Gitlab::Geo::LogHelpers

    # This worker does not perform work scoped to a context
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    idempotent!
    sidekiq_options retry: false, dead: false
    feature_category :geo_replication
    tags :exclude_from_kubernetes, :exclude_from_gitlab_com

    def perform
      Gitlab::Geo.enabled_replicator_classes.each do |replicator_class|
        replicator_class.fail_sync_timeouts
      end
    end
  end
end
