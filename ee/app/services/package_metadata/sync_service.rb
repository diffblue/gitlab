# frozen_string_literal: true

module PackageMetadata
  class SyncService
    UnknownAdapterError = Class.new(StandardError)
    MAX_LEASE_LENGTH = 6.minutes
    MAX_SYNC_DURATION = 4.minutes
    INGEST_SLICE_SIZE = 200
    THROTTLE_RATE = 0.75.seconds

    def self.execute(data_type:, lease:)
      signal = PackageMetadata::StopSignal.new(lease, MAX_LEASE_LENGTH, MAX_SYNC_DURATION)
      SyncConfiguration.configs_for(data_type).each do |sync_config|
        if signal.stop?
          break Gitlab::AppJsonLogger.debug(class: name,
            message: "Stop signal before sync of #{sync_config}")
        end

        new(sync_config, signal).execute
      end
    end

    def initialize(sync_config, signal)
      @sync_config = sync_config
      @signal = signal
    end

    def execute
      connector.data_after(checkpoint).each do |file|
        log_progress(file)

        DataObjectFabricator.new(data_file: file, sync_config: sync_config)
          .each_slice(INGEST_SLICE_SIZE) do |data_objects|
            ingest(data_objects)
            sleep(THROTTLE_RATE)
          end

        checkpoint.update(sequence: file.sequence, chunk: file.chunk)

        if signal.stop?
          return Gitlab::AppJsonLogger.debug(class: self.class.name,
            message: "Stop signal after checkpointing")
        end
      end
    end

    private

    attr_accessor :sync_config, :signal

    def ingest(data)
      if sync_config.advisories?
        PackageMetadata::Ingestion::Advisory::IngestionService.execute(data)
      elsif sync_config.v2?
        PackageMetadata::Ingestion::CompressedPackage::IngestionService.execute(data)
      else
        PackageMetadata::Ingestion::IngestionService.execute(data)
      end
    end

    def checkpoint
      @checkpoint ||= PackageMetadata::Checkpoint
        .with_path_components(sync_config.data_type, sync_config.version_format, sync_config.purl_type)
    end

    def connector
      @connector ||= case sync_config.storage_type
                     when :gcp
                       Gitlab::PackageMetadata::Connector::Gcp.new(sync_config)
                     when :offline
                       Gitlab::PackageMetadata::Connector::Offline.new(sync_config)
                     else
                       raise UnknownAdapterError, "unable to find '#{sync_config.storage_type}' connector"
                     end
    end

    def log_progress(file)
      Gitlab::AppJsonLogger
        .debug(class: self.class.name,
          message: "Evaluating data for #{sync_config}/#{file}")
    end
  end
end
