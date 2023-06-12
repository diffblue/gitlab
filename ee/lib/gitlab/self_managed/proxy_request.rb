# frozen_string_literal: true

module Gitlab
  module SelfManaged
    class ProxyRequest
      def initialize(request, ai_access_token)
        @request = request
        @ai_access_token = ai_access_token
      end

      def workhorse_headers
        # Redirecting to Workhorse using instance level PAT."
        url = URI.join(saas_url, request.path).to_s

        headers = {
          "Authorization" => ["Bearer #{ai_access_token}"],
          "Content-Type" => ["application/json"]
        }

        Gitlab::Workhorse.send_url(url, headers: headers, method: request.request_method)
      end

      private

      attr_reader :ai_access_token, :request

      def saas_url
        ENV['GITLAB_SAAS_URL'] || Gitlab::Saas.com_url
      end
    end
  end
end
