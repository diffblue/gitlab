# frozen_string_literal: true

module EE
  module ContainerRegistry
    module Client
      include ::Gitlab::Utils::StrongMemoize

      Error = Class.new(StandardError)

      # In the future we may want to read a small chunks into memory and use chunked upload
      # it will save us some IO.
      def push_blob(name, digest, file_path)
        payload = Faraday::UploadIO.new(file_path, 'application/octet-stream')
        url = get_upload_url(name, digest)
        headers = { 'Content-Type' => 'application/octet-stream', 'Content-Length' => payload.size.to_s }

        response = faraday.put(url, payload, headers)

        raise Error, "Push Blob error: #{response.body}" unless response.success?

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
      # @return {Object} Returns a Tempfile object or nil when no success
      def pull_blob(name, digest)
        file = Tempfile.new("blob-#{digest}")

        blob_url = "/v2/#{name}/blobs/#{digest}"

        response = HTTP
          .headers({
            'Authorization' => "Bearer #{@options[:token]}", # rubocop:disable Gitlab/ModuleWithInstanceVariables
            'User-Agent' => "GitLab/#{::Gitlab::VERSION}"
           })
          .get(::Gitlab::Utils.append_path(@base_uri, blob_url)) # rubocop:disable Gitlab/ModuleWithInstanceVariables

        if response.status.redirect?
          response = HTTP.get(response['Location'])
        end

        response.body.each do |chunk|
          file.binmode
          file.write(chunk)
        end

        raise Error, "Could not download the blob: #{digest}" unless response.status.success?

        file
      ensure
        file.close
      end

      def repository_raw_manifest(name, reference)
        response_body faraday_raw.get("/v2/#{name}/manifests/#{reference}")
      end

      private

      def get_upload_url(name, digest)
        response = faraday.post("/v2/#{name}/blobs/uploads/")

        raise Error, "Get upload URL error: #{response.body}" unless response.success?

        upload_url = URI(response.headers['location'])
        upload_url.query = "#{upload_url.query}&#{URI.encode_www_form(digest: digest)}"
        upload_url
      end

      # rubocop:disable Gitlab/ModuleWithInstanceVariables
      def faraday_raw
        strong_memoize(:faraday_raw) do
          faraday_base do |conn|
            initialize_connection(conn, @options, &method(:accept_raw_manifest))
          end
        end
      end
      # rubocop:enable Gitlab/ModuleWithInstanceVariables

      def accept_raw_manifest(conn)
        conn.headers['Accept'] = ::ContainerRegistry::Client::ACCEPTED_TYPES_RAW
      end
    end
  end
end
