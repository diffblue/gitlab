# frozen_string_literal: true

module Gitlab
  module Auth
    module Oidc
      class AuthHash < OAuth::AuthHash
        def initialize(auth_hash)
          provider_name = auth_hash.provider
          @oidc_config = Config.options_for(provider_name)

          super
        end

        def groups
          Array.wrap(auth_hash.extra.raw_info[oidc_config.groups_attribute])
        end

        private

        attr_reader :oidc_config
      end
    end
  end
end
