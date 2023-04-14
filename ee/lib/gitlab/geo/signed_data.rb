# frozen_string_literal: true

module Gitlab
  module Geo
    class SignedData
      include LogHelpers

      VALIDITY_PERIOD = 1.minute
      LEEWAY = 60.seconds.to_i

      attr_reader :geo_node

      def initialize(geo_node: nil, validity_period: VALIDITY_PERIOD, include_disabled_nodes: false)
        @geo_node = geo_node
        @validity_period = validity_period
        @include_disabled_nodes = include_disabled_nodes
      end

      def sign_and_encode_data(data)
        raise ::Gitlab::Geo::GeoNodeNotFoundError unless @geo_node

        token = JSONWebToken::HMACToken.new(@geo_node.secret_access_key)
        token.expire_time = Time.zone.now + @validity_period
        token[:data] = data.to_json

        "#{@geo_node.access_key}:#{token.encoded}"
      end

      def decode_data(signed_data)
        return unless signed_data.present?

        parse_data(signed_data)

        return unless @secret_access_key.present? && @encoded_message.present?

        decoded = JWT.decode(
          @encoded_message,
          @secret_access_key,
          true,
          { leeway: LEEWAY, algorithm: 'HS256' }
        )

        message = decoded.first
        data = Gitlab::Json.parse(message['data']) if message
        data&.deep_symbolize_keys!
        data
      rescue JWT::ImmatureSignature, JWT::ExpiredSignature
        message = "Signature not within leeway of #{LEEWAY} seconds. Check your system clocks!"
        log_error(message)
        raise InvalidSignatureTimeError, message
      rescue JWT::DecodeError => e
        log_error("Error decoding Geo request: #{e}")
        nil
      end

      private

      def parse_data(signed_data)
        geo_tokens = signed_data.split(':', 2)

        return unless geo_tokens.count == 2

        @access_key = geo_tokens[0]
        @encoded_message = geo_tokens[1]
        @secret_access_key = hmac_secret
      end

      def hmac_secret
        # By default, we fail authorization for requests from disabled nodes because
        # it is a convenient place to block nearly all requests from disabled
        # secondaries. The `include_disabled_nodes` option can safely override this
        # check for `enabled`.
        #
        # A request is authorized if the access key in the Authorization header
        # matches the access key of the requesting node, **and** the decoded data
        # matches the requested resource.
        scoped_geo_nodes = if @include_disabled_nodes
                             GeoNode.all
                           else
                             GeoNode.enabled
                           end

        @geo_node ||= scoped_geo_nodes.find_by_access_key(@access_key)
        @geo_node&.secret_access_key
      end
    end
  end
end
