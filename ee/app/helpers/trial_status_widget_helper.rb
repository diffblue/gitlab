# frozen_string_literal: true

# NOTE: The patterns first introduced in this helper for doing trial-related
# callouts are mimicked by the PaidFeatureCalloutHelper. A third reuse of these
# patterns (especially as these experiments finish & become permanent parts of
# the codebase) could trigger the need to extract these patterns into a single,
# reusable, sharable helper.
module TrialStatusWidgetHelper
  def trial_status_popover_data_attrs(group)
    hand_raise_attrs = experiment(:group_contact_sales, namespace: group.root_ancestor, user: current_user, sticky_to: current_user) do |e|
      e.control { {} }
      e.candidate { hand_raise_props(group, glm_content: 'trial-status-show-group') }
    end.run

    base_attrs = trial_status_common_data_attrs(group).merge(hand_raise_attrs)

    base_attrs.merge(
      days_remaining: group.trial_days_remaining, # for experiment tracking
      group_name: group.name,
      purchase_href: ultimate_subscription_path_for_group(group),
      target_id: base_attrs[:container_id],
      trial_end_date: group.trial_ends_on
    )
  end

  def trial_status_widget_data_attrs(group)
    trial_status_common_data_attrs(group).merge(
      trial_days_used: group.gitlab_subscription&.trial_days_used,
      trial_duration: group.gitlab_subscription&.trial_duration,
      nav_icon_image_path: image_path('illustrations/golden_tanuki.svg'),
      percentage_complete: group.trial_percentage_complete
    )
  end

  private

  def billing_plans_and_trials_available?
    ::Gitlab::CurrentSettings.should_check_namespace_plan?
  end

  def eligible_for_trial_upgrade_callout?(group)
    group.trial_active? && can?(current_user, :admin_namespace, group)
  end

  def trial_status_common_data_attrs(group)
    {
      container_id: 'trial-status-sidebar-widget',
      plan_name: group.gitlab_subscription&.plan_title,
      plans_href: group_billings_path(group)
    }
  end

  def ultimate_subscription_path_for_group(group)
    new_subscriptions_path(namespace_id: group.id, plan_id: ultimate_plan_id)
  end

  def ultimate_plan_id
    strong_memoize(:ultimate_plan_id) do
      plans = GitlabSubscriptions::FetchSubscriptionPlansService.new(plan: :free).execute

      next unless plans

      plans.find { |data| data['code'] == 'ultimate' }&.fetch('id', nil)
    end
  end
end

TrialStatusWidgetHelper.prepend_mod
