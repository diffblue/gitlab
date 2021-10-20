# frozen_string_literal: true

module Geo
  # This class is responsible for:
  #   * Executing the Downloader
  #   * Marking the Registry record as synced or needing retry
  class FileDownloadService < BaseFileService
    include Gitlab::Utils::StrongMemoize

    LEASE_TIMEOUT = 8.hours.freeze

    include Delay
    include ExclusiveLeaseGuard

    def execute
      try_obtain_lease do
        start_time = Time.current

        download_result = downloader.execute

        mark_as_synced = download_result.success || download_result.primary_missing_file

        log_file_download(mark_as_synced, download_result, start_time)

        update_registry(download_result.bytes_downloaded,
                        mark_as_synced: mark_as_synced,
                        missing_on_primary: download_result.primary_missing_file)
      end
    end

    def downloader
      downloader_klass.new(object_type, object_db_id)
    end

    private

    def downloader_klass
      return Gitlab::Geo::Replication::JobArtifactDownloader if job_artifact?

      fail_unimplemented_klass!(type: 'Downloader')
    end

    def log_file_download(mark_as_synced, download_result, start_time)
      metadata = {
        mark_as_synced: mark_as_synced,
        download_success: download_result.success,
        bytes_downloaded: download_result.bytes_downloaded,
        failed_before_transfer: download_result.failed_before_transfer,
        primary_missing_file: download_result.primary_missing_file,
        reason: download_result.reason,
        download_time_s: (Time.current - start_time).to_f.round(3)
      }.compact

      log_info("File download", metadata)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def registry
      strong_memoize(:registry) do
        Geo::JobArtifactRegistry.find_or_initialize_by(artifact_id: object_db_id)
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def update_registry(bytes_downloaded, mark_as_synced:, missing_on_primary: false)
      registry.bytes = bytes_downloaded
      registry.success = mark_as_synced
      registry.missing_on_primary = missing_on_primary

      retry_later = !registry.success || registry.missing_on_primary

      if retry_later
        custom_max_wait_time = missing_on_primary ? 4.hours : nil

        # We don't limit the amount of retries
        registry.retry_count = (registry.retry_count || 0) + 1
        registry.retry_at = next_retry_time(registry.retry_count, custom_max_wait_time)
      else
        registry.retry_count = 0
        registry.retry_at = nil
      end

      registry.save
    end

    def lease_key
      "file_download_service:#{object_type}:#{object_db_id}"
    end

    def lease_timeout
      LEASE_TIMEOUT
    end
  end
end
