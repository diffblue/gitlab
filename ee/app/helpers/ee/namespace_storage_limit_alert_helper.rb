# frozen_string_literal: true

module EE
  module NamespaceStorageLimitAlertHelper
    extend ::Gitlab::Utils::Override

    def display_namespace_storage_limit_alert?(namespace)
      ::Gitlab::CurrentSettings.should_check_namespace_plan? &&
        !usage_quota_page?(namespace) &&
        can?(current_user, :admin_namespace, namespace.root_ancestor)
    end

    def namespace_storage_alert(namespace)
      return {} unless can?(current_user, :admin_namespace, namespace.root_ancestor)

      payload = check_storage_size_service(namespace).execute.payload

      return {} if payload.empty?

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

    def check_storage_size_service(namespace)
      if namespace.additional_repo_storage_by_namespace_enabled?
        ::Namespaces::CheckExcessStorageSizeService.new(namespace, current_user)
      else
        ::Namespaces::CheckStorageSizeService.new(namespace, current_user)
      end
    end
  end
end
