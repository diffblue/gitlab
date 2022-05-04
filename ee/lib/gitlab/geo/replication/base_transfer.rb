# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      class BaseTransfer
        include LogHelpers

        attr_reader :file_type, :file_id, :filename, :expected_checksum, :request_data, :resource

        TEMP_PREFIX = 'tmp_'
        DOWNLOAD_TIMEOUT = {
          connect: 60,
          write: 60,
          read: 60
        }.freeze

        def initialize(resource:, file_type:, file_id:, request_data:, expected_checksum: nil, filename: nil)
          @resource = resource
          @file_type = file_type
          @file_id = file_id
          @filename = filename
          @expected_checksum = expected_checksum
          @request_data = request_data
        end

        # Return whether the transfer will be attempted or not
        #
        # @return [Boolean] whether preconditions for a transfer are fulfilled
        def can_transfer?
          unless Gitlab::Geo.secondary?
            log_error('Skipping transfer as this is not a Secondary node')

            return false
          end

          unless Gitlab::Geo.primary_node
            log_error 'Skipping transfer as there is no Primary node to download from'

            return false
          end

          if filename && File.directory?(filename)
            log_error 'Skipping transfer as destination exist and is a directory', filename: filename

            return false
          end

          true
        end

        # @return [String] URL to download the resource from
        def resource_url
          Gitlab::Geo.primary_node.geo_transfers_url(url_encode(file_type), file_id.to_s)
        end

        # Returns Result object with success boolean and number of bytes downloaded.
        def download_from_primary
          return skipped_result unless can_transfer?

          unless ensure_destination_path_exists
            log_error 'Skipping transfer as we cannot create the destination directory'

            return skipped_result
          end

          req_headers = TransferRequest.new(request_data).headers

          download_file(resource_url, req_headers)
        end

        def stream_from_primary_to_object_storage
          return skipped_result unless can_transfer?

          req_headers = TransferRequest.new(request_data).headers

          transfer_file_to_object_storage(resource_url, req_headers)
        end

        class Result
          attr_reader :success, :bytes_downloaded, :primary_missing_file, :skipped

          def initialize(success:, bytes_downloaded:, primary_missing_file: false, skipped: false)
            @success = success
            @bytes_downloaded = bytes_downloaded
            @primary_missing_file = primary_missing_file
            @skipped = skipped
          end
        end

        private

        def uploader
          raise NotImplementedError, "#{self.class} does not implement #{__method__}"
        end

        def skipped_result
          Result.new(success: false, bytes_downloaded: 0, skipped: true)
        end

        def failure_result(bytes_downloaded: 0, primary_missing_file: false)
          Result.new(success: false, bytes_downloaded: bytes_downloaded, primary_missing_file: primary_missing_file)
        end

        # Ensure entire destination path exist or try to create when not available
        #
        # @return [Boolean] whether destination path exists or could be created
        def ensure_destination_path_exists
          path = Pathname.new(filename)
          dir = path.dirname

          return true if File.directory?(dir)

          begin
            FileUtils.mkdir_p(dir)
          rescue StandardError => e
            log_error("Unable to create directory #{dir}: #{e}")

            return false
          end

          true
        end

        # Download file from informed URL using HTTP.rb
        #
        # @return [Result] Object with transfer status and information
        def download_file(url, req_headers)
          file_size = -1
          temp_file = open_temp_file(filename)

          return failure_result unless temp_file

          begin
            # Make the request
            response = ::HTTP.timeout(DOWNLOAD_TIMEOUT.dup).get(url, headers: req_headers)

            # Check for failures
            unless response.status.success?
              log_error("Unsuccessful download", filename: filename, status_code: response.status.code, reason: response.status.reason, url: url)

              return failure_result(primary_missing_file: primary_missing_file?(response))
            end

            # Stream to temporary file on disk
            response.body.each do |chunk|
              temp_file.write(chunk)
            end

            # Make sure file is written to the disk
            # This is required to get correct file size.
            temp_file.flush

            file_size = File.stat(temp_file.path).size

            # Check for checksum mismatch
            if checksum_mismatch?(temp_file.path)
              log_error("Downloaded file checksum mismatch", expected_checksum: expected_checksum, actual_checksum: @actual_checksum, file_size_bytes: file_size)

              return failure_result(bytes_downloaded: file_size)
            end

            # Move transferred file to the target location
            FileUtils.mv(temp_file.path, filename)

            log_info("Successfully downloaded", filename: filename, file_size_bytes: file_size)
          rescue StandardError, ::HTTP::Error => e
            log_error("Error downloading file", error: e, filename: filename, url: url)

            return failure_result
          ensure
            temp_file.close
            temp_file.unlink
          end

          Result.new(success: file_size > -1, bytes_downloaded: [file_size, 0].max)
        end

        def transfer_file_to_object_storage(url, req_headers)
          file_size = -1

          # Create a temporary file for Object Storage transfers
          temp_file = Tempfile.new("#{TEMP_PREFIX}-#{file_type}-#{file_id}")
          temp_file.chmod(default_permissions)
          temp_file.binmode

          return failure_result unless temp_file

          begin
            # Make the request
            response = ::HTTP.timeout(DOWNLOAD_TIMEOUT.dup).get(url, headers: req_headers)

            if response.status.redirect?
              response = ::HTTP.timeout(DOWNLOAD_TIMEOUT.dup).get(response['Location'])
            end

            # Check for failures
            unless response.status.success?
              log_error("Unsuccessful download", file_type: file_type, file_id: file_id,
                        status_code: response.status.code, reason: response.status.reason, url: url)

              return failure_result(primary_missing_file: primary_missing_file?(response))
            end

            # Stream to temporary file on disk
            response.body.each do |chunk|
              temp_file.write(chunk)
            end

            file_size = temp_file.size

            # Upload file to Object Storage
            uploader.replace_file_without_saving!(CarrierWave::SanitizedFile.new(temp_file))

            log_info("Successfully transferred", file_type: file_type, file_id: file_id,
                     file_size_bytes: file_size)
          rescue StandardError => e
            log_error("Error transferring file", error: e, file_type: file_type, file_id: file_id, url: url)

            return failure_result
          ensure
            temp_file.close
            temp_file.unlink
          end

          Result.new(success: file_size > -1, bytes_downloaded: [file_size, 0].max)
        end

        def primary_missing_file?(response)
          if response.status.not_found?
            begin
              json_response = response.parse

              return code_file_not_found?(json_response['geo_code'])
            rescue JSON::ParserError
            end
          end

          false
        end

        def code_file_not_found?(geo_code)
          geo_code == Gitlab::Geo::Replication::FILE_NOT_FOUND_GEO_CODE
        end

        def default_permissions
          0666 - File.umask
        end

        def open_temp_file(target_filename)
          # Make sure the file is in the same directory to prevent moves across filesystems
          pathname = Pathname.new(target_filename)
          temp = Tempfile.new(TEMP_PREFIX, pathname.dirname.to_s)
          temp.chmod(default_permissions)
          temp.binmode
          temp
        rescue StandardError => e
          log_error("Error creating temporary file", error: e, filename: target_filename)
          nil
        end

        # @param [String] file_path disk location to compare checksum mismatch
        def checksum_mismatch?(file_path)
          # Skip checksum check if primary didn't generate one because, for
          # example, large attachments are checksummed asynchronously, and most
          # types of artifacts are not checksummed at all at the moment.
          return false if expected_checksum.blank?

          return false unless Feature.enabled?(:geo_file_transfer_validation)

          expected_checksum != actual_checksum(file_path)
        end

        def actual_checksum(file_path)
          @actual_checksum = Digest::SHA256.file(file_path).hexdigest
        end
      end
    end
  end
end
