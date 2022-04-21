# frozen_string_literal: true

module Gitlab
  module Geo
    class JwtRequestDecoder
      include LogHelpers
      include ::Gitlab::Utils::StrongMemoize

      def self.geo_auth_attempt?(header)
        token_type, = header&.split(' ', 2)
        token_type == ::Gitlab::Geo::BaseRequest::GITLAB_GEO_AUTH_TOKEN_TYPE
      end

      attr_reader :auth_header

      def initialize(auth_header)
        @include_disabled = false
        @auth_header = auth_header
      end

      # Return decoded attributes from given header
      #
      # @return [Hash] decoded attributes
      def decode
        strong_memoize(:decoded_authorization) do
          decode_geo_request
        end
      end

      def include_disabled!
        @include_disabled = true
      end

      # Check if set of attributes match against attributes decoded from JWT
      #
      # @param [Hash] attributes to be matched against JWT
      # @return bool true
      def valid_attributes?(**attributes)
        decoded_attributes = decode

        return false if decoded_attributes.nil?

        attributes.all? { |attribute, value| decoded_attributes[attribute] == value }
      end

      private

      def decode_geo_request
        # A Geo request has an Authorization header:
        # Authorization: GL-Geo: <Geo Access Key>:<JWT payload>
        #
        # For example:
        # JWT payload = { "data": { "oid": "12345" }, iat: 123456 }
        #
        signed_data = parse_auth_header

        Gitlab::Geo::SignedData.new(include_disabled_nodes: @include_disabled).decode_data(signed_data)
      rescue OpenSSL::Cipher::CipherError
        message = 'Error decrypting the Geo secret from the database. Check that the primary and secondary have the same db_key_base.'
        log_error(message)
        raise InvalidDecryptionKeyError, message
      end

      def parse_auth_header
        return unless auth_header.present?

        tokens = auth_header.split(' ')

        return unless tokens.count == 2
        return unless tokens[0] == Gitlab::Geo::BaseRequest::GITLAB_GEO_AUTH_TOKEN_TYPE

        tokens[1]
      end
    end
  end
end
