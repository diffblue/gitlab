# frozen_string_literal: true

module PackageMetadata
  class SyncWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    data_consistency :always
    feature_category :license_compliance
    urgency :low

    idempotent!

    def perform
      return unless Feature.enabled?(:package_metadata_synchronization)

      SyncService.execute
    end
  end
end
