# frozen_string_literal: true

module EE
  module NamespaceUserCapReachedAlertHelper
    def display_namespace_user_cap_reached_alert?(namespace)
      root_namespace = namespace.root_ancestor
      return false unless ::Feature.enabled?(:saas_user_caps, root_namespace, default_enabled: :yaml)

      return false if root_namespace.user_namespace?

      can?(current_user, :admin_namespace, root_namespace) && user_cap_reached?(root_namespace)
    end

    private

    def user_cap_reached?(root_namespace)
      Rails.cache.fetch("namespace_user_cap_reached:#{root_namespace.id}", expires_in: 2.hours) do
        root_namespace.user_cap_reached?
      end
    end
  end
end
