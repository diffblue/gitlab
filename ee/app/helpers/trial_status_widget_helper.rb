# frozen_string_literal: true

# NOTE: The patterns first introduced in this helper for doing trial-related
# callouts are mimicked by the PaidFeatureCalloutHelper. A third reuse of these
# patterns (especially as these experiments finish & become permanent parts of
# the codebase) could trigger the need to extract these patterns into a single,
# reusable, sharable helper.
module TrialStatusWidgetHelper
  def trial_status_popover_data_attrs(group, trial_status, ultimate_plan_id)
    base_attrs = trial_status_common_data_attrs(group).merge(
      hand_raise_props(group, glm_content: 'trial-status-show-group')
    )

    base_attrs.merge(
      days_remaining: trial_status.days_remaining,
      target_id: base_attrs[:container_id],
      trial_end_date: trial_status.ends_on
    )
  end

  def trial_status_widget_data_attrs(group, trial_status)
    trial_status_common_data_attrs(group).merge(
      trial_days_used: trial_status.days_used,
      trial_duration: trial_status.duration,
      nav_icon_image_path: image_path('illustrations/golden_tanuki.svg'),
      percentage_complete: trial_status.percentage_complete
    )
  end

  private

  def trial_status_common_data_attrs(group)
    {
      container_id: 'trial-status-sidebar-widget',
      plan_name: group.gitlab_subscription.plan_title,
      plans_href: group_billings_path(group)
    }
  end

  def ultimate_subscription_path_for_group(group, ultimate_plan_id)
    new_subscriptions_path(namespace_id: group.id, plan_id: ultimate_plan_id)
  end
end

TrialStatusWidgetHelper.prepend_mod
