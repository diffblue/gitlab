# frozen_string_literal: true

module EE
  module NamespaceStorageLimitAlertHelper
    def namespace_storage_alert(namespace)
      storage_notification = EE::Namespace::Storage::Notification.new(namespace, current_user)
      return {} unless storage_notification.show?

      payload = storage_notification.payload

      alert_level = payload[:alert_level]
      root_namespace = payload[:root_namespace]

      return {} if cookies["hide_storage_limit_alert_#{root_namespace.id}_#{alert_level}"] == 'true'

      payload
    end

    def namespace_storage_alert_style(alert_level)
      if alert_level == :error || alert_level == :alert
        :danger
      else
        alert_level
      end
    end

    def namespace_storage_alert_icon(alert_level)
      if alert_level == :error || alert_level == :alert
        'error'
      elsif alert_level == :info
        'information-o'
      else
        alert_level.to_s
      end
    end

    def purchase_storage_link_enabled?(namespace)
      namespace.additional_repo_storage_by_namespace_enabled?
    end

    def purchase_storage_url
      EE::SUBSCRIPTIONS_MORE_STORAGE_URL
    end

    def number_of_hidden_storage_alert_banners
      cookies.count { |key, value| key.starts_with?("hide_storage_limit_alert") && value == "true" }
    end

    private

    def usage_quota_page?(namespace)
      current_page?(group_usage_quotas_path(namespace)) || current_page?(profile_usage_quotas_path)
    end
  end
end
