# frozen_string_literal: true

module DependencyProxy
  module Packages
    module Maven
      class VerifyPackageFileEtagService
        TIMEOUT_ERROR_CODE = 599

        def initialize(remote_url:, package_file:)
          @remote_url = remote_url
          @package_file = package_file
        end

        def execute
          return ServiceResponse.error(message: 'invalid arguments', reason: :invalid_arguments) unless valid?

          response = ::Gitlab::HTTP.head(remote_url, follow_redirects: true)

          return error_with_response_code(response.code) unless response.success?
          return ServiceResponse.success if etag_match?(package_file, response)

          ServiceResponse.error(
            message: "etag from external registry doesn't match any known digests",
            reason: :wrong_etag
          )
        rescue Timeout::Error
          error_with_response_code(TIMEOUT_ERROR_CODE)
        end

        private

        attr_reader :remote_url, :package_file

        def etag_match?(package_file, response)
          etag = sanitize_etag(response)
          return false unless etag

          # We don't know how etag is computed on the remote url.
          # We thus check all the digests we know.
          %i[md5 sha1 sha256].any? { |digest| etag == package_file["file_#{digest}"] }
        end

        def sanitize_etag(response)
          etag = response.headers["etag"]
          return unless etag

          etag.delete('"')
        end

        def valid?
          remote_url.present? && package_file
        end

        def error_with_response_code(code)
          message = "Received #{code} from external registry"
          Gitlab::AppLogger.error(
            service_class: self.class.to_s,
            project_id: package_file.package&.project_id,
            message: message
          )

          ServiceResponse.error(message: message, reason: :response_error_code)
        end
      end
    end
  end
end
