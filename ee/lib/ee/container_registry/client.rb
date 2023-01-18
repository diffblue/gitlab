# frozen_string_literal: true

module EE
  module ContainerRegistry
    module Client
      include ::Gitlab::Utils::StrongMemoize

      Error = Class.new(StandardError)

      def push_blob(name, digest, blob_io, size)
        response = HTTP
          .headers(base_headers.merge('Content-Length' => size))
          .put(get_upload_url(name, digest), body: blob_io)

        raise Error, "Push Blob error: #{response.body}" unless response.status.success?

        true
      end

      def push_manifest(name, tag, manifest, manifest_type)
        response = faraday.put("v2/#{name}/manifests/#{tag}", manifest, { 'Content-Type' => manifest_type })

        raise Error, "Push manifest error: #{response.body}" unless response.success?

        true
      end

      def blob_exists?(name, digest)
        faraday.head("/v2/#{name}/blobs/#{digest}").success?
      end

      # Pulls a blob from the Registry.
      # We currently use Faraday 0.12 which does not support streaming download yet
      # Given that we aim to migrate to HTTP.rb client and that updating Faraday is potentially
      # dangerous, we use HTTP.rb here.
      #
      # @return [Array] Returns a Enumerator reader and the size of the object
      def pull_blob(name, digest)
        blob_url = "/v2/#{name}/blobs/#{digest}"

        response = HTTP
          .headers(base_headers)
          .get(::Gitlab::Utils.append_path(base_uri, blob_url))

        if response.status.redirect?
          response = HTTP.get(response['Location'])
        end

        raise Error, "Could not download the blob: #{digest}" unless response.status.success?

        [response.body, response.headers['Content-Length'].to_i]
      end

      def repository_raw_manifest(name, reference)
        response_body faraday_raw.get("/v2/#{name}/manifests/#{reference}")
      end

      private

      # Used to set HTTP.rb client
      def base_headers
        {
          'Authorization' => "bearer #{options[:token]}",
          'User-Agent' => "GitLab/#{::Gitlab::VERSION}"
        }
      end

      def get_upload_url(name, digest)
        response = faraday.post("/v2/#{name}/blobs/uploads/")

        raise Error, "Get upload URL error: #{response.body}" unless response.success?

        upload_url = URI(response.headers['location'])
        upload_url.query = "#{upload_url.query}&#{URI.encode_www_form(digest: digest)}"
        upload_url
      end

      def faraday_raw
        strong_memoize(:faraday_raw) do
          faraday_base do |conn|
            initialize_connection(conn, options) { |connection| accept_raw_manifest(connection) }
          end
        end
      end

      def accept_raw_manifest(conn)
        conn.headers['Accept'] = ::ContainerRegistry::Client::ACCEPTED_TYPES_RAW
      end
    end
  end
end
