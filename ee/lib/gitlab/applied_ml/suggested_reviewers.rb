# frozen_string_literal: true

module Gitlab
  module AppliedMl
    module SuggestedReviewers
      INTERNAL_API_REQUEST_HEADER = 'Gitlab-Suggested-Reviewers-Api-Request'
      JWT_ISSUER = 'gitlab-suggested-reviewers'
      EXPIRATION = 5.minutes

      include JwtAuthenticatable

      class << self
        def verify_api_request(request_headers)
          token = request_headers[INTERNAL_API_REQUEST_HEADER]
          return unless token

          decode_jwt(
            token,
            issuer: JWT_ISSUER,
            iat_after: Time.current - EXPIRATION
          )
        rescue JWT::DecodeError
          nil
        end

        def secret_path
          Gitlab.config.suggested_reviewers.secret_file
        end

        def ensure_secret!
          return if File.exist?(secret_path)

          write_secret
        end
      end
    end
  end
end
