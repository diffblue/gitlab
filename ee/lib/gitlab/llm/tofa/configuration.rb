# frozen_string_literal: true

module Gitlab
  module Llm
    module Tofa
      class Configuration
        def access_token
          Rails.cache.fetch(
            :tofa_access_token,
            expires_in: tofa_access_token_expires_in.to_i.seconds,
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
          :tofa_access_token_expires_in,
          :tofa_client_library_args,
          :tofa_client_library_class,
          :tofa_client_library_create_credentials_method,
          :tofa_client_library_fetch_access_token_method,
          :tofa_credentials,
          :tofa_host,
          :tofa_request_json_keys,
          :tofa_request_payload,
          :tofa_url,
          to: :settings
        )

        def fresh_token
          client_library_class = tofa_client_library_class.constantize
          client_library_args = string_to_hash(tofa_client_library_args)
          first_key = client_library_args.first[0]
          client_library_args[first_key] = StringIO.new(tofa_credentials)
          create_credentials_method = tofa_client_library_create_credentials_method.to_sym
          fetch_access_token_method = tofa_client_library_fetch_access_token_method.to_sym

          # rubocop:disable GitlabSecurity/PublicSend
          response = client_library_class.public_send(
            create_credentials_method,
            **client_library_args
          ).public_send(fetch_access_token_method)
          # rubocop:enable GitlabSecurity/PublicSend

          response["access_token"]
        end

        def string_to_hash(str)
          hash = {}

          str.split(", ").each do |pair|
            key, value = pair.split(" ")
            value = value == "nil" ? nil : value
            hash[key.to_sym] = value
          end

          hash
        end
      end
    end
  end
end
