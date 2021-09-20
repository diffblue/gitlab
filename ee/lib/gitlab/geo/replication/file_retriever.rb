# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      # This class is responsible for:
      #   * Finding an Upload record
      #   * Returning the necessary response data to send the file back
      #
      class FileRetriever < BaseRetriever
        def execute
          return error('Upload not found') unless recorded_file
          return file_not_found(recorded_file) unless recorded_file.exist?
          return error('Invalid request') unless valid?
          return error('Checksum mismatch') unless matches_checksum?

          success(recorded_file.retrieve_uploader)
        end

        private

        def recorded_file
          strong_memoize(:recorded_file) do
            Upload.find_by_id(object_db_id)
          end
        end

        def valid?
          return false if extra_params.nil?

          extra_params[:id] == recorded_file.model_id &&
            extra_params[:type] == recorded_file.model_type
        end

        def matches_checksum?
          # Remove this when we implement checksums for files on the Object Storage
          return true unless recorded_file.local?

          extra_params[:checksum] == Upload.sha256_hexdigest(recorded_file.absolute_path)
        end
      end
    end
  end
end
