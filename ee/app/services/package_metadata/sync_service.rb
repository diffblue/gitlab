# frozen_string_literal: true

module PackageMetadata
  class SyncService
    UnknownAdapterError = Class.new(StandardError)
    INGEST_SLICE_SIZE = 1000

    def self.execute
      SyncConfiguration.all.each do |config|
        connector = connector_for(config)
        new(connector, config.version_format, config.purl_type).execute
      end
    end

    def self.connector_for(config)
      case config.storage_type
      when :gcp
        Gitlab::PackageMetadata::Connector::Gcp.new(config.base_uri, config.version_format, config.purl_type)
      when :offline
        Gitlab::PackageMetadata::Connector::Offline.new(config.base_uri, config.version_format, config.purl_type)
      else
        raise UnknownAdapterError, "unable to find '#{config.storage_type}' connector"
      end
    end

    def initialize(connector, version_format, purl_type)
      @connector = connector
      @version_format = version_format
      @purl_type = purl_type
    end

    def execute
      connector.data_after(checkpoint).each do |csv_file|
        csv_file.each_slice(INGEST_SLICE_SIZE) do |data_objects|
          ingest(data_objects)
        end
        checkpoint.update(sequence: csv_file.sequence, chunk: csv_file.chunk)
      end
    end

    private

    attr_accessor :connector, :version_format, :purl_type

    def ingest(data)
      Ingestion::IngestionService.execute(data)
    end

    def checkpoint
      @checkpoint ||= PackageMetadata::Checkpoint.with_purl_type(purl_type)
    end
  end
end
