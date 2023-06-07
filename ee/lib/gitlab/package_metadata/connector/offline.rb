# frozen_string_literal: true

module Gitlab
  module PackageMetadata
    module Connector
      class Offline
        def initialize(archive_path, version_format, purl_type)
          @version_format = version_format
          @purl_type = purl_type

          registry_id = ::PackageMetadata::SyncConfiguration.registry_id(purl_type)
          path_components = [archive_path, version_format, registry_id]

          @file_prefix = File.join(path_components)
          @file_suffix = version_format == ::PackageMetadata::SyncConfiguration::VERSION_FORMAT_V2 ? "ndjson" : "csv"
        end

        def data_after(checkpoint = nil)
          filepaths = Dir.glob("*/*.#{file_suffix}", base: file_prefix).sort!

          pending_filepaths = pending_files(filepaths, checkpoint)

          fetch_pending_files(pending_filepaths, purl_type)
        end

        private

        attr_reader :file_prefix, :file_suffix, :version_format, :purl_type

        def pending_files(filepaths, checkpoint)
          # If no checkpoint exists iterate through all filepaths.
          return filepaths if checkpoint.blank?

          # Find index of last checkpointed file.
          checkpoint_index = filepaths.find_index do |filepath|
            # Extract sequence from structure of files: <sequence>/<chunk>.csv
            sequence = File.dirname(filepath).delete_prefix(File::SEPARATOR).to_i
            chunk = File.basename(filepath, ".#{file_suffix}").to_i

            sequence.to_i == checkpoint.sequence && chunk.to_i == checkpoint.chunk
          end

          # If the checkpoint was not found, then replay the ingestion to guarantee
          # data consistency.
          return filepaths if checkpoint_index.nil?

          # Drop all filepaths including the last checkpointed file since they've
          # been processed previously by a worker.
          filepaths.drop(checkpoint_index + 1)
        end

        def fetch_pending_files(filepaths, purl_type)
          filepaths.lazy.map do |filepath|
            path = File.absolute_path(filepath, file_prefix)
            DataFile.new(path, file_prefix, file_suffix, version_format, purl_type)
          end
        end

        class DataFile
          include Enumerable

          attr_reader :filepath, :sequence, :chunk, :version_format, :purl_type

          def initialize(filepath, file_prefix, file_suffix, version_format, purl_type)
            relative_path = filepath.delete_prefix(file_prefix)

            @filepath = filepath
            @version_format = version_format
            @purl_type = purl_type
            @sequence = File.dirname(relative_path).delete_prefix(File::SEPARATOR).to_i
            @chunk = File.basename(relative_path, file_suffix).to_i
          end

          def each(&blk)
            File.readlines(filepath).map do |line|
              data_object = parse(line, purl_type)

              yield data_object if data_object
            end
          end

          def parse(line, purl_type)
            if version_format == ::PackageMetadata::SyncConfiguration::VERSION_FORMAT_V2
              ::PackageMetadata::CompressedPackageDataObject.parse(line, purl_type)
            else
              ::PackageMetadata::DataObject.from_csv(line, purl_type)
            end
          end
        end
      end
    end
  end
end
