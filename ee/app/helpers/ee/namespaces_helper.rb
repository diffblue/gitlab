# frozen_string_literal: true

module EE
  module NamespacesHelper
    extend ::Gitlab::Utils::Override

    def ci_minutes_report(usage_report)
      content_tag(:span, class: "shared_runners_limit_#{usage_report.status}") do
        "#{usage_report.used} / #{usage_report.limit}"
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

    def buy_additional_minutes_path(namespace)
      return EE::SUBSCRIPTIONS_MORE_MINUTES_URL if use_customers_dot_for_addon_path?(namespace)

      buy_minutes_subscriptions_path(selected_group: namespace.root_ancestor.id)
    end

    def buy_addon_target_attr(namespace)
      use_customers_dot_for_addon_path?(namespace) ? '_blank' : '_self'
    end

    def buy_storage_path(namespace)
      return EE::SUBSCRIPTIONS_MORE_STORAGE_URL if use_customers_dot_for_addon_path?(namespace)

      buy_storage_subscriptions_path(selected_group: namespace.root_ancestor.id)
    end

    def buy_storage_url(namespace)
      return EE::SUBSCRIPTIONS_MORE_STORAGE_URL if use_customers_dot_for_addon_path?(namespace)

      buy_storage_subscriptions_url(selected_group: namespace.root_ancestor.id)
    end

    override :pipeline_usage_app_data
    def pipeline_usage_app_data(namespace)
      return super unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

      minutes_usage = namespace.ci_minutes_usage
      minutes_usage_presenter = ::Ci::Minutes::UsagePresenter.new(minutes_usage)

      super.merge(
        ci_minutes: {
          any_project_enabled: minutes_usage_presenter.any_project_enabled?.to_s,
          last_reset_date: minutes_usage.reset_date,
          display_minutes_available_data: minutes_usage_presenter.display_minutes_available_data?.to_s,
          monthly_minutes_used: minutes_usage_presenter.monthly_minutes_report.used,
          monthly_minutes_used_percentage: minutes_usage_presenter.monthly_percent_used,
          monthly_minutes_limit: minutes_usage_presenter.monthly_minutes_report.limit,
          purchased_minutes_used: minutes_usage_presenter.purchased_minutes_report.used,
          purchased_minutes_used_percentage: minutes_usage_presenter.purchased_percent_used,
          purchased_minutes_limit: minutes_usage_presenter.purchased_minutes_report.limit
        },
        buy_additional_minutes_path: buy_additional_minutes_path(namespace),
        buy_additional_minutes_target: buy_addon_target_attr(namespace)
      )
    end

    def storage_usage_app_data(namespace)
      data = {
        namespace_id: namespace.id,
        namespace_path: namespace.full_path,
        purchase_storage_url: nil,
        buy_addon_target_attr: nil,
        default_per_page: page_size,
        additional_repo_storage_by_namespace: current_user.namespace.additional_repo_storage_by_namespace_enabled?.to_s,
        is_free_namespace: (!current_user.namespace.paid?).to_s,
        is_personal_namespace: true
      }

      if purchase_storage_link_enabled?(namespace)
        data.merge!({
          purchase_storage_url: purchase_storage_url,
          buy_addon_target_attr: buy_addon_target_attr(namespace)
        })
      end

      data
    end

    def purchase_storage_link_enabled?(namespace)
      namespace.additional_repo_storage_by_namespace_enabled?
    end

    def purchase_storage_url
      EE::SUBSCRIPTIONS_MORE_STORAGE_URL
    end

    private

    def use_customers_dot_for_addon_path?(namespace)
      namespace.user_namespace?
    end
  end
end
