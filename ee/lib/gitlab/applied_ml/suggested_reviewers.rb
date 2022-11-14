# frozen_string_literal: true

module Gitlab
  module AppliedMl
    module SuggestedReviewers
      INTERNAL_API_REQUEST_HEADER = 'Gitlab-Sugggested-Reviewers-Api-Request'
      JWT_ISSUER = 'gitlab-suggested-reviewers'
      SECRET_NAME = 'GITLAB_SUGGESTED_REVIEWERS_API_SECRET'
      SECRET_LENGTH = 64

      include Gitlab::Utils::StrongMemoize
      include JwtAuthenticatable

      class << self
        def verify_api_request(request_headers)
          token = request_headers[INTERNAL_API_REQUEST_HEADER]
          return unless token

          decode_jwt(token, issuer: JWT_ISSUER)
        rescue JWT::DecodeError
          nil
        end

        # rubocop:disable Gitlab/StrongMemoizeAttr
        def secret
          strong_memoize(:secret) do
            ENV.fetch(SECRET_NAME)
          end
        end
        # rubocop:enable Gitlab/StrongMemoizeAttr

        def ensure_secret!
          secret = ENV[SECRET_NAME]

          raise Gitlab::AppliedMl::Errors::ConfigurationError, "Variable #{SECRET_NAME} is missing" if secret.blank?

          if secret.length != SECRET_LENGTH
            raise Gitlab::AppliedMl::Errors::ConfigurationError,
                  "Secret must contain #{SECRET_LENGTH} bytes"
          end

          secret
        end
      end
    end
  end
end
