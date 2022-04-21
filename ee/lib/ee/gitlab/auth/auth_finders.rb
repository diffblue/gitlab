# frozen_string_literal: true

module EE
  module Gitlab
    module Auth
      module AuthFinders
        extend ActiveSupport::Concern
        extend ::Gitlab::Utils::Override

        def find_user_from_geo_token
          return unless geo_api_request?

          token = current_request.authorization
          return unless ::Gitlab::Geo::JwtRequestDecoder.geo_auth_attempt?(token)

          token_data = parse_geo_token(token)
          raise(::Gitlab::Auth::UnauthorizedError) unless
            token_data.is_a?(Hash) && token_data[:scope] == ::Gitlab::Geo::API_SCOPE

          ::User.find(token_data[:authenticating_user_id])
        rescue ::ActiveRecord::RecordNotFound
          raise(::Gitlab::Auth::UnauthorizedError)
        end

        def parse_geo_token(token)
          geo_jwt_decoder = ::Gitlab::Geo::JwtRequestDecoder.new(token)
          geo_jwt_decoder.decode
        rescue ::Gitlab::Geo::InvalidDecryptionKeyError, ::Gitlab::Geo::InvalidSignatureTimeError => e
          ::Gitlab::ErrorTracking.track_exception(e)
          nil
        end

        override :find_oauth_access_token
        def find_oauth_access_token
          return if scim_request?

          super
        end

        def scim_request?
          current_request.path.starts_with?("/api/scim/")
        end

        def geo_api_request?
          current_request.path.starts_with?("/api/#{::API::API.version}/geo/")
        end
      end
    end
  end
end
