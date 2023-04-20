# frozen_string_literal: true

module Geo
  class BlobDownloadService
    include ExclusiveLeaseGuard
    include Gitlab::Geo::LogHelpers

    # Imagine a multi-gigabyte LFS object file and an instance on the other side
    # of the earth
    LEASE_TIMEOUT = 8.hours.freeze

    # Initialize a new blob downloader service
    #
    # @param [Gitlab::Geo::Replicator] replicator instance
    def initialize(replicator:)
      @replicator = replicator
    end

    # Downloads a blob from the primary and places it where it should be. And
    # records sync status in Registry.
    #
    # Exits early if another instance is running for the same replicable model.
    #
    # @return [Boolean] true if synced, false if not
    def execute
      try_obtain_lease do
        start_time = Time.current

        registry.start!

        download_result = ::Gitlab::Geo::Replication::BlobDownloader.new(replicator: @replicator).execute

        mark_as_synced = download_result.success

        if mark_as_synced
          registry.synced!
        else
          message = download_result.reason
          error = download_result.extra_details&.fetch(:error, nil)

          registry.failed!(message: message, error: error, missing_on_primary: download_result.primary_missing_file)
        end

        log_download(mark_as_synced, download_result, start_time)

        !!mark_as_synced
      end
    end

    private

    def registry
      @registry ||= @replicator.registry
    end

    def log_download(mark_as_synced, download_result, start_time)
      metadata = {
        mark_as_synced: mark_as_synced,
        download_success: download_result.success,
        bytes_downloaded: download_result.bytes_downloaded,
        primary_missing_file: download_result.primary_missing_file,
        download_time_s: (Time.current - start_time).to_f.round(3),
        reason: download_result.reason
      }
      metadata.merge(download_result.extra_details) if download_result.extra_details

      log_info("Blob download", metadata)
    end

    def lease_key
      @lease_key ||= "#{self.class.name.underscore}:#{@replicator.replicable_name}:#{@replicator.model_record.id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
