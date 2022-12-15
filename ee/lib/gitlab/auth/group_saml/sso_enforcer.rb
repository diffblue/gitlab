# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class SsoEnforcer
        DEFAULT_SESSION_TIMEOUT = 1.day

        attr_reader :saml_provider, :user

        def initialize(saml_provider, user: nil)
          @saml_provider = saml_provider
          @user = user
        end

        def update_session
          SsoState.new(saml_provider.id).update_active(DateTime.now)
        end

        def active_session?
          if ::Feature.enabled?(:enforced_sso_expiry, group)
            SsoState.new(saml_provider.id).active_since?(DEFAULT_SESSION_TIMEOUT.ago)
          else
            SsoState.new(saml_provider.id).active?
          end
        end

        def access_restricted?
          saml_enforced? && !active_session?
        end

        def self.group_access_restricted?(group, user: nil, for_project: false)
          return false unless group
          return false unless group.root_ancestor

          saml_provider = group.root_saml_provider

          return false unless saml_provider
          return false if user_authorized?(user, group, for_project)

          new(saml_provider, user: user).access_restricted?
        end

        private

        def saml_enforced?
          return true if saml_provider&.enforced_sso?
          return false unless user && group
          return false unless transparent_sso_enabled?
          return false unless saml_provider&.enabled? && group.licensed_feature_available?(:group_saml)

          user.group_sso?(group)
        end

        def group
          saml_provider&.group
        end

        def self.user_authorized?(user, group, for_project)
          return false if for_project

          !group.has_parent? && group.owned_by?(user)
        end

        # Override feature flag allows selective disabling by actor
        # See https://docs.gitlab.com/ee/development/feature_flags/controls.html#selectively-disable-by-actor
        def transparent_sso_enabled?
          Feature.enabled?(:transparent_sso_enforcement, group) &&
            Feature.disabled?(:transparent_sso_enforcement_override, group)
        end
      end
    end
  end
end
