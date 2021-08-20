# frozen_string_literal: true

module EE
  module NamespacesHelper
    extend ::Gitlab::Utils::Override

    def ci_minutes_report(quota_report)
      content_tag(:span, class: "shared_runners_limit_#{quota_report.status}") do
        "#{quota_report.used} / #{quota_report.limit}"
      end
    end

    def ci_minutes_progress_bar(percent)
      status =
        if percent >= 95
          'danger'
        elsif percent >= 70
          'warning'
        else
          'success'
        end

      width = [percent, 100].min

      options = {
        class: "progress-bar bg-#{status}",
        style: "width: #{width}%;"
      }

      content_tag :div, class: 'progress' do
        content_tag :div, nil, options
      end
    end

    def temporary_storage_increase_visible?(namespace)
      return false unless ::Gitlab::CurrentSettings.enforce_namespace_storage_limit?
      return false unless ::Feature.enabled?(:temporary_storage_increase, namespace)

      current_user.can?(:admin_namespace, namespace.root_ancestor)
    end

    def link_to_buy_additional_minutes_path(namespace)
      use_customer_dot_path = namespace.user? || ::Feature.disabled?(:new_route_ci_minutes_purchase, namespace, default_enabled: :yaml)
      return EE::SUBSCRIPTIONS_MORE_MINUTES_URL if use_customer_dot_path

      buy_minutes_subscriptions_path(selected_group: namespace.id)
    end
  end
end
