# frozen_string_literal: true

module EE
  module Gitlab
    module Auth
      module RequestAuthenticator
        extend ::Gitlab::Utils::Override

        override :find_sessionless_user
        def find_sessionless_user(request_format)
          find_user_from_geo_token || super(request_format)
        rescue ::Gitlab::Auth::AuthenticationError
          nil
        end
      end
    end
  end
end
