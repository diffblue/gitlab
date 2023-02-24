# frozen_string_literal: true

module Gitlab
  module PackageMetadata
    module Connector
      class Offline
        def initialize(archive_path, version_format, purl_type)
          @purl_type = purl_type

          registry_id = ::PackageMetadata::SyncConfiguration.registry_id(purl_type)
          @file_prefix = File.join(archive_path, version_format, registry_id).freeze
        end

        def data_after(checkpoint = nil)
          filepaths = Dir.glob("*/*.csv", base: file_prefix).sort!

          pending_filepaths = pending_files(filepaths, checkpoint)

          fetch_pending_files(pending_filepaths, purl_type)
        end

        private

        attr_reader :file_prefix, :purl_type

        def pending_files(filepaths, checkpoint)
          # If no checkpoint exists iterate through all filepaths.
          return filepaths if checkpoint.blank?

          # Find index of last checkpointed file.
          checkpoint_index = filepaths.find_index do |filepath|
            # Extract sequence from structure of files: <sequence>/<chunk>.csv
            sequence = File.dirname(filepath).delete_prefix(File::SEPARATOR).to_i
            chunk = File.basename(filepath, ".csv").to_i

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
            CsvFile.new(path, file_prefix, purl_type)
          end
        end

        class CsvFile
          include Enumerable

          attr_reader :filepath, :sequence, :chunk, :purl_type

          def initialize(filepath, file_prefix, purl_type)
            relative_path = filepath.delete_prefix(file_prefix)

            @filepath = filepath
            @purl_type = purl_type
            @sequence = File.dirname(relative_path).delete_prefix(File::SEPARATOR).to_i
            @chunk = File.basename(relative_path, ".csv").to_i
          end

          def each(&blk)
            File.readlines(filepath).map do |line|
              data_object = ::PackageMetadata::DataObject.from_csv(line, purl_type)

              yield data_object if data_object
            end
          end
        end
      end
    end
  end
end
