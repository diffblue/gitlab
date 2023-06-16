# frozen_string_literal: true

module Gitlab
  module CodeSuggestions
    class AccessToken
      JWT_AUDIENCE = 'gitlab-code-suggestions'
      NOT_BEFORE_TIME = 5.seconds.to_i.freeze
      EXPIRES_IN = 1.hour.to_i.freeze

      # Authentication realms
      GITLAB_REALM_SAAS = 'saas'
      GITLAB_REALM_SELF_MANAGED = 'self-managed'

      NoSigningKeyError = Class.new(StandardError)

      attr_reader :issued_at

      def initialize(user, gitlab_realm: GITLAB_REALM_SAAS)
        @id = SecureRandom.uuid
        @audience = JWT_AUDIENCE
        @issuer = Doorkeeper::OpenidConnect.configuration.issuer
        @issued_at = Time.now.to_i
        @not_before = @issued_at - NOT_BEFORE_TIME
        @expire_time = @issued_at + EXPIRES_IN
        @user = user
        @gitlab_realm = gitlab_realm
      end

      def encoded
        headers = { typ: 'JWT' }

        JWT.encode(payload.merge(claims), key, 'RS256', headers)
      end

      def payload
        {
          jti: @id,
          aud: @audience,
          iss: @issuer,
          iat: @issued_at,
          nbf: @not_before,
          exp: @expire_time
        }
      end

      private

      def claims
        {
          third_party_ai_features_enabled: @user.third_party_ai_features_enabled?,
          gitlab_realm: @gitlab_realm
        }
      end

      def key
        key_data = Rails.application.secrets.openid_connect_signing_key

        raise NoSigningKeyError unless key_data

        OpenSSL::PKey::RSA.new(key_data)
      end
    end
  end
end
