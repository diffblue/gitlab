# frozen_string_literal: true

module Gitlab
  module CustomersDot
    class Jwt
      DEFAULT_EXPIRE_TIME = 60 * 10

      NoSigningKeyError = Class.new(StandardError)

      def initialize(user)
        @user = user
      end

      def encoded
        headers = { typ: 'JWT' }

        JWT.encode(payload, key, 'RS256', headers)
      end

      def payload
        now = Time.now.to_i

        {
          jti: SecureRandom.uuid,
          iss: Settings.gitlab.host,
          iat: now,
          exp: now + DEFAULT_EXPIRE_TIME,
          sub: "gitlab_user_id_#{user.id}"
        }
      end

      private

      attr_reader :user

      def key
        key_data = Gitlab::CurrentSettings.customers_dot_jwt_signing_key

        raise NoSigningKeyError unless key_data

        OpenSSL::PKey::RSA.new(key_data)
      end
    end
  end
end
