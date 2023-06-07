# frozen_string_literal: true

module PackageMetadata
  class SyncService
    UnknownAdapterError = Class.new(StandardError)
    INGEST_SLICE_SIZE = 200
    THROTTLE_RATE = 0.75.seconds
    LICENSES_DATA_TYPE = :licenses

    def self.execute(signal)
      SyncConfiguration.all_by_enabled_purl_type.each do |config|
        if signal.stop?
          break Gitlab::AppJsonLogger.debug(class: name,
            message: "Stop signal received before starting #{config.purl_type} sync")
        end

        connector = connector_for(config)
        new(connector, config.version_format, config.purl_type, signal).execute
      end
    end

    def self.connector_for(config)
      case config.storage_type
      when :gcp
        Gitlab::PackageMetadata::Connector::Gcp.new(config.base_uri, config.version_format, config.purl_type)
      when :offline
        Gitlab::PackageMetadata::Connector::Offline.new(config.class.archive_path, config.version_format,
          config.purl_type)
      else
        raise UnknownAdapterError, "unable to find '#{config.storage_type}' connector"
      end
    end

    def initialize(connector, version_format, purl_type, signal)
      @connector = connector
      @version_format = version_format
      @purl_type = purl_type
      @signal = signal
    end

    def execute
      connector.data_after(checkpoint).each do |data_file|
        Gitlab::AppJsonLogger.debug(class: self.class.name,
          message: "Evaluating data for #{purl_type}/#{version_format}/#{data_file.sequence}/#{data_file.chunk}")

        data_file.each_slice(INGEST_SLICE_SIZE) do |data_objects|
          ingest(data_objects)
          sleep(THROTTLE_RATE)
        end

        checkpoint.update(sequence: data_file.sequence, chunk: data_file.chunk)

        if signal.stop?
          return Gitlab::AppJsonLogger.debug(class: self.class.name,
            message: "Stopping #{purl_type} sync after checkpointing")
        end
      end
    end

    def data_type
      LICENSES_DATA_TYPE
    end

    private

    attr_accessor :connector, :version_format, :purl_type, :signal

    def ingest(data)
      if version_format == SyncConfiguration::VERSION_FORMAT_V2
        PackageMetadata::Ingestion::CompressedPackage::IngestionService.execute(data)
      else
        PackageMetadata::Ingestion::IngestionService.execute(data)
      end
    end

    def checkpoint
      @checkpoint ||= PackageMetadata::Checkpoint.with_path_components(data_type, version_format, purl_type)
    end
  end
end
