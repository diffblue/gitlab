# frozen_string_literal: true

module Gitlab
  module PackageMetadata
    module Connector
      class Offline < BaseConnector
        def data_after(checkpoint = nil)
          filepaths = Dir.glob("*/*.#{file_suffix}", base: file_prefix).sort!

          pending_filepaths = pending_files(filepaths, checkpoint)

          fetch_pending_files(pending_filepaths)
        end

        private

        def file_prefix
          File.join(sync_config.base_uri, super)
        end

        def file_separator
          File::SEPARATOR
        end

        def pending_files(filepaths, checkpoint)
          # If no checkpoint exists iterate through all filepaths.
          return filepaths if checkpoint.blank?

          # Find index of last checkpointed file.
          checkpoint_index = filepaths.find_index do |filepath|
            sequence, chunk = sequence_and_chunk_from(filepath)

            sequence == checkpoint.sequence && chunk == checkpoint.chunk
          end

          # If the checkpoint was not found, then replay the ingestion to guarantee
          # data consistency.
          return filepaths if checkpoint_index.nil?

          # Drop all filepaths including the last checkpointed file since they've
          # been processed previously by a worker.
          filepaths.drop(checkpoint_index + 1)
        end

        def fetch_pending_files(filepaths)
          filepaths.lazy.map do |filepath|
            path = File.absolute_path(filepath, file_prefix)
            io = File.open(path, 'r')

            sequence, chunk = sequence_and_chunk_from(filepath)

            data_file_class.new(io, sequence, chunk)
          end
        end
      end
    end
  end
end
