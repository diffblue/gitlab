# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      class Configuration
        DEFAULT_SCOPE = 'https://www.googleapis.com/auth/cloud-platform'
        DEFAULT_TEMPERATURE = 0.5
        DEFAULT_MAX_TOKENS = 1024
        DEFAULT_TOP_K = 40
        DEFAULT_TOP_P = 0.95

        def initialize(model_config:)
          @model_config = model_config
        end

        def self.default_payload_parameters
          {
            temperature: DEFAULT_TEMPERATURE,
            maxOutputTokens: DEFAULT_MAX_TOKENS,
            topK: DEFAULT_TOP_K,
            topP: DEFAULT_TOP_P
          }
        end

        def access_token
          Rails.cache.fetch(
            :tofa_access_token,
            expires_in: 3540.seconds,
            skip_nil: true
          ) do
            fresh_token
          end
        end

        def headers
          {
            "Accept" => "application/json",
            "Authorization" => "Bearer #{access_token}",
            "Host" => model_config.host,
            "Content-Type" => "application/json"
          }
        end

        private

        attr_reader :model_config

        delegate :host, :url, :payload, to: :model_config
        delegate :tofa_credentials, to: :settings

        def settings
          @settings ||= Gitlab::CurrentSettings.current_application_settings
        end

        def fresh_token
          response = ::Google::Auth::ServiceAccountCredentials.make_creds(
            json_key_io: StringIO.new(tofa_credentials),
            scope: DEFAULT_SCOPE
          ).fetch_access_token!

          response["access_token"]
        end
      end
    end
  end
end
