# frozen_string_literal: true

module BillingPlansHelper
  include Gitlab::Utils::StrongMemoize

  def subscription_plan_info(plans_data, current_plan_code)
    current_plan = plans_data.find { |plan| plan.code == current_plan_code && plan.current_subscription_plan? }
    current_plan || plans_data.find { |plan| plan.code == current_plan_code }
  end

  def number_to_plan_currency(value)
    number_to_currency(value, unit: '$', strip_insignificant_zeros: true, format: "%u%n")
  end

  def upgrade_offer_type(namespace, plan)
    return :no_offer if namespace.actual_plan_name != Plan::BRONZE || !offer_from_previous_tier?(namespace.id, plan.id)

    upgrade_for_free?(namespace.id) ? :upgrade_for_free : :upgrade_for_offer
  end

  def has_upgrade?(upgrade_offer)
    [:upgrade_for_free, :upgrade_for_offer].include?(upgrade_offer)
  end

  def show_contact_sales_button?(purchase_link_action, upgrade_offer)
    return false unless purchase_link_action == 'upgrade'

    [:upgrade_for_offer, :no_offer].include?(upgrade_offer)
  end

  def show_upgrade_button?(purchase_link_action, upgrade_offer)
    return false unless purchase_link_action == 'upgrade'

    [:no_offer, :upgrade_for_free].include?(upgrade_offer)
  end

  def subscription_plan_data_attributes(namespace, plan)
    return {} unless namespace

    {
      namespace_id: namespace.id,
      namespace_name: namespace.name,
      add_seats_href: add_seats_url(namespace),
      plan_renew_href: plan_renew_url(namespace),
      customer_portal_url: EE::SUBSCRIPTIONS_MANAGE_URL,
      billable_seats_href: billable_seats_href(namespace),
      plan_name: plan&.name
    }.tap do |attrs|
      if Feature.enabled?(:refresh_billings_seats, type: :ops, default_enabled: :yaml)
        attrs[:refresh_seats_href] = refresh_seats_group_billings_url(namespace)
      end
    end
  end

  def use_new_purchase_flow?(namespace)
    # new flow requires the user to already have a last name.
    # This can be removed once https://gitlab.com/gitlab-org/gitlab/-/issues/298715 is complete.
    return false unless current_user.last_name.present?

    namespace.group_namespace? && (namespace.actual_plan_name == Plan::FREE || namespace.trial_active?)
  end

  def plan_feature_list(plan)
    return [] unless plan.features

    plan.features.sort_by! { |feature| feature.highlight ? 0 : 1 }
  end

  def plan_purchase_or_upgrade_url(group, plan)
    if group.upgradable?
      plan_upgrade_url(group, plan)
    else
      plan_purchase_url(group, plan)
    end
  end

  def show_plans?(namespace)
    if namespace.free_personal?
      false
    elsif namespace.trial_active?
      true
    else
      !highest_tier?(namespace)
    end
  end

  def show_trial_banner?(namespace)
    return false unless params[:trial]

    root = namespace.has_parent? ? namespace.root_ancestor : namespace
    root.trial_active?
  end

  def namespace_for_user?(namespace)
    namespace == current_user.namespace
  end

  def seats_data_last_update_info
    last_enqueue_time = UpdateMaxSeatsUsedForGitlabComSubscriptionsWorker.last_enqueue_time&.utc
    return _("Seats usage data as of %{last_enqueue_time} (Updated daily)" % { last_enqueue_time: last_enqueue_time }) if last_enqueue_time

    _('Seats usage data is updated every day at 12:00pm UTC')
  end

  def upgrade_button_text(plan_offer_type)
    plan_offer_type === :upgrade_for_free ? s_('BillingPlan|Upgrade for free') : s_('BillingPlan|Upgrade')
  end

  def upgrade_button_css_classes(namespace, plan, is_current_plan)
    css_classes = []

    css_classes << 'disabled' if is_current_plan && !namespace.trial_active?
    css_classes << 'invisible' if ::Feature.enabled?(:hide_deprecated_billing_plans) && plan.deprecated?
    css_classes << "billing-cta-purchase#{'-new' if use_new_purchase_flow?(namespace)}"

    css_classes.join(' ')
  end

  def billing_available_plans(plans_data, current_plan)
    return plans_data unless ::Feature.enabled?(:hide_deprecated_billing_plans)

    plans_data.reject do |plan_data|
      if plan_data.code == current_plan&.code
        plan_data.deprecated? && plan_data.hide_deprecated_card?
      else
        plan_data.deprecated?
      end
    end
  end

  def show_start_free_trial_messages?(namespace)
    !namespace.free_personal? && namespace.eligible_for_trial?
  end

  def plan_purchase_url(group, plan)
    if use_new_purchase_flow?(group)
      new_subscriptions_path(plan_id: plan.id, namespace_id: group.id, source: params[:source])
    else
      "#{plan.purchase_link.href}&gl_namespace_id=#{group.id}"
    end
  end

  def hand_raise_props(namespace, glm_content: )
    {
      namespace_id: namespace.id,
      user_name: current_user.username,
      first_name: current_user.first_name,
      last_name: current_user.last_name,
      company_name: current_user.organization,
      glm_content: glm_content
    }
  end

  def billing_upgrade_button_data(plan)
    data = {
      track_action: 'click_button',
      track_label: 'upgrade',
      track_property: plan.code,
      qa_selector: "upgrade_to_#{plan.code}"
    }

    add_billing_in_side_nav_attribute(data)
  end

  def start_free_trial_data
    data = {
      track_action: 'click_button',
      track_label: 'start_trial',
      qa_selector: 'start_your_free_trial'
    }

    add_billing_in_side_nav_attribute(data)
  end

  def accessed_billing_from_side_nav?
    params[:from] == 'side_nav'
  end

  private

  def add_billing_in_side_nav_attribute(data)
    return data unless accessed_billing_from_side_nav?

    data.merge!(track_experiment: :billing_in_side_nav)
  end

  def add_seats_url(group)
    return unless group

    ::Gitlab::SubscriptionPortal.add_extra_seats_url(group.id)
  end

  def plan_upgrade_url(group, plan)
    return unless group && plan&.id

    ::Gitlab::SubscriptionPortal.upgrade_subscription_url(group.id, plan.id)
  end

  def plan_renew_url(group)
    return unless group

    ::Gitlab::SubscriptionPortal.renew_subscription_url(group.id)
  end

  def billable_seats_href(namespace)
    return unless namespace.group_namespace?

    group_usage_quotas_path(namespace, anchor: 'seats-quota-tab')
  end

  def offer_from_previous_tier?(namespace_id, plan_id)
    upgrade_plan_id = upgrade_plan_data(namespace_id)[:upgrade_plan_id]

    return false unless upgrade_plan_id

    upgrade_plan_id == plan_id
  end

  def upgrade_for_free?(namespace_id)
    !!upgrade_plan_data(namespace_id)[:upgrade_for_free]
  end

  def upgrade_plan_data(namespace_id)
    strong_memoize(:upgrade_plan_data) do
      GitlabSubscriptions::PlanUpgradeService
        .new(namespace_id: namespace_id)
        .execute
    end
  end

  def highest_tier?(namespace)
    namespace.gold_plan? || namespace.ultimate_plan?
  end
end

BillingPlansHelper.prepend_mod
