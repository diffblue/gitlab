# frozen_string_literal: true

module Gitlab
  module Geo
    module Replication
      class BlobDownloader
        TEMP_PREFIX = 'tmp_'
        DOWNLOAD_TIMEOUT = {
          connect: 60,
          write: 60,
          read: 60
        }.freeze

        attr_reader :replicator

        delegate :primary_checksum, :carrierwave_uploader, to: :replicator
        delegate :file_storage?, to: :carrierwave_uploader

        class Result
          attr_reader :success, :bytes_downloaded, :primary_missing_file, :reason, :extra_details

          def initialize(success:, bytes_downloaded:, primary_missing_file: false, reason: nil, extra_details: nil)
            @success = success
            @bytes_downloaded = bytes_downloaded
            @primary_missing_file = primary_missing_file
            @reason = reason
            @extra_details = extra_details
          end
        end

        def initialize(replicator:)
          @replicator = replicator
        end

        # Download the file to a tempfile, then put it where it belongs.
        #
        # @return [Result] a result object containing all relevant information
        def execute
          check_result = check_preconditions
          return check_result if check_result

          temp_file = open_temp_file
          return temp_file if temp_file.is_a?(Result)

          begin
            result = download_file(resource_url, request_headers, temp_file)
          ensure
            temp_file.close
            temp_file.unlink
          end

          result
        end

        # @return [String] URL to download the resource from
        def resource_url
          Gitlab::Geo.primary_node.geo_retrieve_url(**replicator.replicable_params)
        end

        private

        # Encodes data about the requested resource in the authorization header.
        # The primary will decode it and compare the decoded data to the
        # requested resource. If decoding works and the data makes sense, then
        # this proves to the primary that the secondary knows its GeoNode's
        # secret_access_key.
        #
        # @return [Hash] HTTP request headers
        def request_headers
          request_data = replicator.replicable_params

          TransferRequest.new(request_data).headers
        end

        # Returns nil if passed preconditions, otherwise returns a Result object
        #
        # @return [Result] a result object with skipped reason
        def check_preconditions
          unless Gitlab::Geo.secondary?
            return failure_result(reason: 'Skipping transfer as this is not a Secondary node')
          end

          unless Gitlab::Geo.primary_node
            return failure_result(reason: 'Skipping transfer as there is no Primary node to download from')
          end

          if file_storage?
            if File.directory?(absolute_path)
              return failure_result(reason: 'Skipping transfer as destination exist and is a directory')
            end

            unless ensure_destination_path_exists
              return failure_result(reason: 'Skipping transfer as we cannot create the destination directory')
            end
          else
            unless sync_object_storage_enabled?
              return failure_result(reason: 'Skipping transfer as this secondary node is not allowed to replicate content on Object Storage')
            end

            unless object_store_enabled?
              return failure_result(reason: "Skipping transfer as this secondary node is not configured to store #{replicator.replicable_name} on Object Storage")
            end
          end

          nil
        end

        def sync_object_storage_enabled?
          Gitlab::Geo.current_node.sync_object_storage
        end

        def object_store_enabled?
          carrierwave_uploader.class.object_store_enabled?
        end

        def absolute_path
          carrierwave_uploader.path
        end

        def failure_result(bytes_downloaded: 0, primary_missing_file: false, reason: nil, extra_details: nil)
          Result.new(success: false, bytes_downloaded: bytes_downloaded, primary_missing_file: primary_missing_file, reason: reason, extra_details: extra_details)
        end

        # Ensure entire destination path exist or try to create when not available
        #
        # @return [Boolean] whether destination path exists or could be created
        def ensure_destination_path_exists
          path = Pathname.new(absolute_path)
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
        def download_file(url, req_headers, temp_file)
          file_size = -1

          # Make the request
          response = ::HTTP.timeout(DOWNLOAD_TIMEOUT.dup).get(url, headers: req_headers)

          if response.status.redirect?
            # ::HTTP.follow passes through all headers (including our
            # `Authorization: Gl-Geo ...` header) when the primary uses object
            # storage with direct download.
            # https://gitlab.com/gitlab-org/gitlab/-/issues/323495
            #
            # So we manually follow the redirect instead.
            response = ::HTTP.timeout(DOWNLOAD_TIMEOUT.dup).get(response['Location'])
          end

          # Check for failures
          unless response.status.success?
            return non_success_response_result(response, url)
          end

          # Stream to temporary file on disk
          response.body.each do |chunk|
            temp_file.write(chunk)
          end

          file_size = temp_file.size

          # Check for checksum mismatch
          if checksum_mismatch?(temp_file.path)
            return failure_result(bytes_downloaded: file_size, reason: "Downloaded file checksum mismatch", extra_details: { primary_checksum: primary_checksum, actual_checksum: @actual_checksum })
          end

          carrierwave_uploader.replace_file_without_saving!(CarrierWave::SanitizedFile.new(temp_file))

          Result.new(success: true, bytes_downloaded: [file_size, 0].max)
        rescue StandardError => e
          failure_result(bytes_downloaded: file_size, reason: "Error downloading file", extra_details: { error: e, url: url })
        end

        def primary_missing_file?(response)
          return false unless response.status.not_found?
          return false unless response.content_type.mime_type == 'application/json'

          json_response = response.parse

          code_file_not_found?(json_response['geo_code'])
        rescue JSON::ParserError
          false
        end

        def code_file_not_found?(geo_code)
          geo_code == Gitlab::Geo::Replication::FILE_NOT_FOUND_GEO_CODE
        end

        def default_permissions
          0666 - File.umask
        end

        def open_temp_file
          if file_storage?
            # Make sure the file is in the same directory to prevent moves across filesystems
            pathname = Pathname.new(absolute_path)
            temp = Tempfile.new(TEMP_PREFIX, pathname.dirname.to_s)
          else
            temp = Tempfile.new("#{TEMP_PREFIX}-#{replicator.replicable_name}-#{replicator.model_record_id}")
          end

          temp.chmod(default_permissions)
          temp.binmode
          temp
        rescue StandardError => e
          details = { error: e }
          details.merge({ absolute_path: absolute_path }) if absolute_path

          failure_result(reason: "Error creating temporary file", extra_details: details)
        end

        # @param [String] file_path disk location to compare checksum mismatch
        def checksum_mismatch?(file_path)
          # Skip checksum check if primary didn't generate one because, for
          # example, large attachments are checksummed asynchronously, and most
          # types of artifacts are not checksummed at all at the moment.
          return false if primary_checksum.blank?

          primary_checksum != actual_checksum(file_path)
        end

        def actual_checksum(file_path)
          @actual_checksum = Digest::SHA256.file(file_path).hexdigest
        end

        def non_success_response_result(response, url)
          primary_missing_file = primary_missing_file?(response)
          reason = if primary_missing_file
                     "The file is missing on the Geo primary site"
                   else
                     "Non-success HTTP response status code #{response.status.code}"
                   end

          failure_result(
            primary_missing_file: primary_missing_file,
            reason: reason,
            extra_details: {
              status_code: response.status.code,
              reason: response.status.reason,
              url: url
            }
          )
        end
      end
    end
  end
end
