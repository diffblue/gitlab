# frozen_string_literal: true

module EE
  module NamespacesHelper
    extend ::Gitlab::Utils::Override

    def ci_minutes_report(usage_report)
      content_tag(:span, class: "shared_runners_limit_#{usage_report.status}") do
        "#{usage_report.used} / #{usage_report.limit}"
      end
    end

    def buy_additional_minutes_path(namespace)
      return more_minutes_url if use_customers_dot_for_addon_path?(namespace)

      buy_minutes_subscriptions_path(selected_group: namespace.root_ancestor.id)
    end

    def buy_addon_target_attr(namespace)
      use_customers_dot_for_addon_path?(namespace) ? '_blank' : '_self'
    end

    def buy_storage_path(namespace)
      return purchase_storage_url if use_customers_dot_for_addon_path?(namespace)

      buy_storage_subscriptions_path(selected_group: namespace.root_ancestor.id)
    end

    def buy_storage_url(namespace)
      return purchase_storage_url if use_customers_dot_for_addon_path?(namespace)

      buy_storage_subscriptions_url(selected_group: namespace.root_ancestor.id)
    end

    override :pipeline_usage_app_data
    def pipeline_usage_app_data(namespace)
      minutes_usage = namespace.ci_minutes_usage
      minutes_usage_presenter = ::Ci::Minutes::UsagePresenter.new(minutes_usage)

      # EE data
      ci_minutes = {
        any_project_enabled: minutes_usage_presenter.any_project_enabled?.to_s,
        last_reset_date: minutes_usage.reset_date,
        display_minutes_available_data: minutes_usage_presenter.display_minutes_available_data?.to_s,
        monthly_minutes_used: minutes_usage_presenter.monthly_minutes_report.used,
        monthly_minutes_used_percentage: minutes_usage_presenter.monthly_percent_used,
        monthly_minutes_limit: minutes_usage_presenter.monthly_minutes_report.limit
      }

      return super.merge(ci_minutes: ci_minutes) unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

      # SaaS data
      ci_minutes.merge!({
        purchased_minutes_used: minutes_usage_presenter.purchased_minutes_report.used,
        purchased_minutes_used_percentage: minutes_usage_presenter.purchased_percent_used,
        purchased_minutes_limit: minutes_usage_presenter.purchased_minutes_report.limit
      })

      super.merge(
        ci_minutes: ci_minutes,
        buy_additional_minutes_path: buy_additional_minutes_path(namespace),
        buy_additional_minutes_target: buy_addon_target_attr(namespace)
      )
    end

    override :storage_usage_app_data
    def storage_usage_app_data(namespace)
      return super unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

      super.merge({
        purchase_storage_url: buy_storage_path(namespace),
        buy_addon_target_attr: buy_addon_target_attr(namespace),
        storage_limit_enforced: ::Namespaces::Storage::Enforcement.enforce_limit?(namespace).to_s,
        can_show_inline_alert: project_storage_limit_enforced?(namespace).to_s
      })
    end

    def project_storage_limit_enforced?(namespace)
      namespace.root_storage_size.enforce_limit? &&
        namespace.root_storage_size.enforcement_type == :project_repository_limit
    end

    def purchase_storage_url
      ::Gitlab::Routing.url_helpers.subscription_portal_more_storage_url
    end

    private

    def more_minutes_url
      ::Gitlab::Routing.url_helpers.subscription_portal_more_minutes_url
    end

    def use_customers_dot_for_addon_path?(namespace)
      namespace.user_namespace?
    end
  end
end
