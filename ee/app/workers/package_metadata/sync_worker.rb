# frozen_string_literal: true

module PackageMetadata
  class SyncWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
    include ExclusiveLeaseGuard

    LEASE_TIMEOUT = 5.minutes
    MAX_SYNC_DURATION = 4.minutes

    data_consistency :always
    feature_category :software_composition_analysis
    urgency :low

    idempotent!
    sidekiq_options retry: false
    worker_has_external_dependencies!

    def perform
      return unless should_run?

      try_obtain_lease do
        stop_signal = StopSignal.new(exclusive_lease)
        SyncService.execute(stop_signal)
      end
    end

    def lease_timeout
      LEASE_TIMEOUT
    end

    StopSignal = Struct.new(:lease) do
      def stop?
        MAX_SYNC_DURATION < lease_time_elapsed
      end

      def lease_time_elapsed
        LEASE_TIMEOUT - lease.ttl
      end
    end

    private

    def should_run?
      return false unless Feature.enabled?(:package_metadata_synchronization)
      return false unless ::License.feature_available?(:license_scanning)
      return false if Rails.env.development? && ENV.fetch('PM_SYNC_IN_DEV', 'false') != 'true'

      true
    end
  end
end
