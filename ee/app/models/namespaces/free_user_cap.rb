# frozen_string_literal: true

module Namespaces
  module FreeUserCap
    REACHED_LIMIT_VARIANT = 'reached'
    CLOSE_TO_LIMIT_VARIANT = 'close'
    NOTIFICATION_LIMIT_VARIANT = 'notification'

    def self.notification_or_enforcement_enabled?(namespace)
      # should only be needed temporarily while notification is still in codebase
      # after notification is removed, we should merely call `Enforcement` in the
      # places that use this. For notification cleanup https://gitlab.com/gitlab-org/gitlab/-/issues/356561
      ::Namespaces::FreeUserCap::Notification.new(namespace).enforce_cap? ||
        ::Namespaces::FreeUserCap::Enforcement.new(namespace).enforce_cap?
    end

    def self.over_user_limit_mails_enabled?
      ::Feature.enabled?(:free_user_cap_over_user_limit_mails)
    end

    def self.dashboard_limit
      ::Gitlab::CurrentSettings.dashboard_limit
    end

    def self.owner_access?(user:, namespace:)
      return false unless user

      Ability.allowed?(user, :owner_access, namespace)
    end

    def self.non_owner_access?(user:, namespace:)
      return false unless user
      return false if owner_access?(user: user, namespace: namespace)

      Ability.allowed?(user, :read_group, namespace)
    end
  end
end

Namespaces::FreeUserCap.prepend_mod
