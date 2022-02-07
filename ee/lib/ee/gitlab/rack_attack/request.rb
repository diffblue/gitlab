# frozen_string_literal: true

module EE
  module Gitlab
    module RackAttack
      module Request
        extend ::Gitlab::Utils::Override

        override :should_be_skipped?
        def should_be_skipped?
          super || geo?
        end

        def geo?
          if env['HTTP_AUTHORIZATION']
            ::Gitlab::Geo::JwtRequestDecoder.geo_auth_attempt?(env['HTTP_AUTHORIZATION'])
          else
            false
          end
        end

        def alerts_notify?
          web_request? && logical_path.include?('alerts/notify')
        end
      end
    end
  end
end
