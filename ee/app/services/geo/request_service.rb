# frozen_string_literal: true

module Geo
  class RequestService
    private

    def execute(url, body, method: Net::HTTP::Post, with_response: false)
      return false if url.nil?

      response = Gitlab::HTTP.perform_request(method, url, body: body, allow_local_requests: true, headers: headers, timeout: timeout)

      unless response.success?
        handle_failure_for(response)
        return false
      end

      return response.parsed_response if with_response

      true
    rescue Gitlab::HTTP::Error, Timeout::Error, SocketError, SystemCallError, OpenSSL::SSL::SSLError => e
      log_error("Failed to #{method} to primary url: #{url}", e)
      false
    end

    def handle_failure_for(response)
      message = "Could not connect to Geo primary node - HTTP Status Code: #{response.code} #{response.message}"
      payload = response.parsed_response
      details =
        if payload.is_a?(Hash)
          payload['message']
        else
          # The return value can be a giant blob of HTML; ignore it
          ''
        end

      log_error([message, details].compact.join("\n"))
    end

    def primary_node
      Gitlab::Geo.primary_node
    rescue OpenSSL::Cipher::CipherError => e
      log_error('Error decrypting the Geo secret from the database. Check that the primary uses the correct db_key_base.', e)
      nil
    end

    def headers
      Gitlab::Geo::BaseRequest.new(scope: ::Gitlab::Geo::API_SCOPE).headers
    rescue Gitlab::Geo::GeoNodeNotFoundError => e
      log_error('Geo primary node could not be found', e)
    rescue OpenSSL::Cipher::CipherError => e
      log_error('Error decrypting the Geo secret from the database. Check that the primary uses the correct db_key_base.', e)
      nil
    end

    def timeout
      Gitlab::CurrentSettings.geo_status_timeout
    end
  end
end
