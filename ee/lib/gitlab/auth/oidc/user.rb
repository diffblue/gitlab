# frozen_string_literal: true

# OAuth extension for User model
#
# * Find GitLab user based on omniauth uid and provider
# * Create new user from omniauth data
#
module Gitlab
  module Auth
    module Oidc
      class User < OAuth::User
        def initialize(auth_hash)
          provider_name = auth_hash.provider
          @oidc_config = Config.options_for(provider_name)

          super
        end

        def find_user
          return if required_groups_enabled? && !user_in_required_group?

          user = super

          if user
            user.admin = user_in_admin_group? if admin_groups_enabled?
            user.external = user_in_external_group? if external_groups_enabled?
          end

          user
        end

        private

        attr_reader :oidc_config

        def auth_hash=(auth_hash)
          @auth_hash = Oidc::AuthHash.new(auth_hash)
        end

        def required_groups_enabled?
          required_groups = oidc_config.required_groups
          required_groups.any?
        end

        def admin_groups_enabled?
          oidc_config.admin_groups.any?
        end

        def external_groups_enabled?
          oidc_config.external_groups.any?
        end

        def user_in_required_group?
          required_groups = oidc_config.required_groups
          (auth_hash.groups & required_groups).any?
        end

        def user_in_admin_group?
          return false if user_in_external_group?

          admin_groups = oidc_config.admin_groups
          (auth_hash.groups & admin_groups).any?
        end

        def user_in_external_group?
          external_groups = oidc_config.external_groups
          (auth_hash.groups & external_groups).any?
        end
      end
    end
  end
end
