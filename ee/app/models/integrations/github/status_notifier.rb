# frozen_string_literal: true

module Integrations
  class Github
    class StatusNotifier
      def initialize(access_token, repo_path, api_endpoint: nil)
        @access_token = access_token
        @repo_path = repo_path
        @api_endpoint = api_endpoint.presence || ::Octokit::Default.api_endpoint
      end

      def notify(ref, state, params = {})
        client.create_status(@repo_path, ref, state, params).to_h
      end

      def last_client_response
        client.last_response
      end

      private

      def client
        @client ||= Octokit::Client.new(access_token: @access_token, api_endpoint: @api_endpoint)
      end
    end
  end
end
