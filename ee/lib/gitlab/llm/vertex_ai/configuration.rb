# frozen_string_literal: true

module Gitlab
  module Llm
    module VertexAi
      class Configuration
        DEFAULT_SCOPE = 'https://www.googleapis.com/auth/cloud-platform'

        def access_token
          Rails.cache.fetch(
            :tofa_access_token,
            expires_in: 3540.seconds,
            skip_nil: true
          ) do
            fresh_token
          end
        end

        def host
          tofa_host
        end

        def url
          tofa_url
        end

        private

        def settings
          @settings ||= Gitlab::CurrentSettings.current_application_settings
        end

        delegate(
          :tofa_credentials,
          :tofa_host,
          :tofa_url,
          to: :settings
        )

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
