# frozen_string_literal: true

module Gitlab
  module Auth
    module GroupSaml
      class SsoEnforcer
        DEFAULT_SESSION_TIMEOUT = 1.day

        class << self
          def access_restricted?(user:, resource:)
            group = resource.is_a?(::Group) ? resource : resource.group

            return false unless group

            saml_provider = group.root_saml_provider

            return false unless saml_provider
            return false if user_authorized?(user, group, resource)

            new(saml_provider, user: user).access_restricted?
          end

          # Given an array of groups or subgroups, return an array
          # of root groups that are access restricted for the user
          def access_restricted_groups(groups, user: nil)
            return [] unless groups.any?

            ::Preloaders::GroupRootAncestorPreloader.new(groups, [:saml_provider]).execute
            root_ancestors = groups.map(&:root_ancestor).uniq

            root_ancestors.select do |root_ancestor|
              new(root_ancestor.saml_provider, user: user).access_restricted?
            end
          end

          private

          def user_authorized?(user, group, resource)
            return true if resource.public? && !group_member?(group, user)
            return true if user&.can_read_all_resources?
            return true if resource.is_a?(::Group) && resource.root? && resource.owned_by?(user)

            false
          end

          def group_member?(group, user)
            user && user.is_a?(::User) && group.member?(user)
          end
        end

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
      end
    end
  end
end
