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
          SsoState.new(saml_provider.id).active_since?(DEFAULT_SESSION_TIMEOUT.ago)
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

        # Given an array of groups or subgroups, return an array
        # of root groups that are access restricted for the user
        def self.access_restricted_groups(groups, user: nil)
          return [] unless groups.any?

          ::Preloaders::GroupRootAncestorPreloader.new(groups, [:saml_provider]).execute
          root_ancestors = groups.map(&:root_ancestor).uniq

          root_ancestors.select do |root_ancestor|
            group_access_restricted?(root_ancestor, user: user, for_project: true)
          end
        end

        private

        def saml_enforced?
          return true if saml_provider&.enforced_sso?
          return false unless user && group
          return false unless saml_provider&.enabled? && group.licensed_feature_available?(:group_saml)

          user.group_sso?(group)
        end

        def group
          saml_provider&.group
        end

        def self.user_authorized?(user, group, for_project)
          return false unless user
          return true if user.can_read_all_resources?

          return false if for_project

          !group.has_parent? && group.owned_by?(user)
        end
      end
    end
  end
end
