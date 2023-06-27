# frozen_string_literal: true

module Gitlab
  module PackageMetadata
    module Connector
      class BaseConnector
        def initialize(sync_config)
          @sync_config = sync_config
        end

        private

        attr_reader :sync_config

        def sequence_and_chunk_from(filename)
          filename
             .delete_prefix(file_prefix)
             .delete_suffix(file_suffix)
             .split(file_separator).map(&:to_i)
        end

        def data_file_class
          if sync_config.v2?
            ::Gitlab::PackageMetadata::Connector::NdjsonDataFile
          else
            ::Gitlab::PackageMetadata::Connector::CsvDataFile
          end
        end

        def file_prefix
          File.join(sync_config.version_format, registry_id)
        end

        def registry_id
          ::PackageMetadata::SyncConfiguration.registry_id(sync_config.purl_type)
        end

        def file_suffix
          data_file_class.file_suffix
        end

        def file_separator
          '/'
        end
      end
    end
  end
end
