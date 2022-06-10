# frozen_string_literal: true

module EE
  module NamespaceUserCapReachedAlertHelper
    def display_namespace_user_cap_reached_alert?(namespace)
      # On pages that are not under a namespace like the group creation page,
      # we only receive a non-persisted Namespace record as default.
      return false unless namespace&.persisted?

      root_namespace = namespace.root_ancestor

      return false unless root_namespace.user_cap_available?
      return false if alert_has_been_dismissed?(root_namespace)
      return false if current_page?(pending_members_group_usage_quotas_path(root_namespace))

      can?(current_user, :admin_namespace, root_namespace) && root_namespace.user_cap_reached?(use_cache: true)
    end

    def hide_user_cap_alert_cookie_id(root_namespace)
      "hide_user_cap_alert_#{root_namespace.id}"
    end

    private

    def alert_has_been_dismissed?(root_namespace)
      cookies[hide_user_cap_alert_cookie_id(root_namespace)] == 'true'
    end
  end
end
