# frozen_string_literal: true

module Gitlab
  module CodeSuggestions
    class AccessToken
      JWT_AUDIENCE = 'gitlab-code-suggestions'
      NOT_BEFORE_TIME = 5.seconds.to_i.freeze
      EXPIRES_IN = 1.hour.to_i.freeze

      NoSigningKeyError = Class.new(StandardError)

      attr_reader :issued_at

      def initialize
        @id = SecureRandom.uuid
        @audience = JWT_AUDIENCE
        @issuer = Doorkeeper::OpenidConnect.configuration.issuer
        @issued_at = Time.now.to_i
        @not_before = @issued_at - NOT_BEFORE_TIME
        @expire_time = @issued_at + EXPIRES_IN
      end

      def encoded
        headers = { typ: 'JWT' }

        JWT.encode(payload, key, 'RS256', headers)
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

      def key
        key_data = Rails.application.secrets.openid_connect_signing_key

        raise NoSigningKeyError unless key_data

        OpenSSL::PKey::RSA.new(key_data)
      end
    end
  end
end
