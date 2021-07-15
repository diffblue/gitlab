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
    upgrade_offer == :upgrade_for_free || upgrade_offer == :upgrade_for_offer
  end

  def show_contact_sales_button?(purchase_link_action, upgrade_offer)
    return false unless purchase_link_action == 'upgrade'

    upgrade_offer == :upgrade_for_offer ||
      (experiment_enabled?(:contact_sales_btn_in_app) && upgrade_offer == :no_offer)
  end

  def show_upgrade_button?(purchase_link_action, upgrade_offer)
    purchase_link_action == 'upgrade' &&
      (upgrade_offer == :no_offer || upgrade_offer == :upgrade_for_free)
  end

  def subscription_plan_data_attributes(namespace, plan)
    return {} unless namespace

    {
      namespace_id: namespace.id,
      namespace_name: namespace.name,
      add_seats_href: add_seats_url(namespace),
      plan_upgrade_href: plan_upgrade_url(namespace, plan),
      plan_renew_href: plan_renew_url(namespace),
      customer_portal_url: "#{EE::SUBSCRIPTIONS_URL}/subscriptions",
      billable_seats_href: billable_seats_href(namespace),
      plan_name: plan&.name,
      free_personal_namespace: namespace.free_personal?.to_s
    }
  end

  def use_new_purchase_flow?(namespace)
    # new flow requires the user to already have a last name.
    # This can be removed once https://gitlab.com/gitlab-org/gitlab/-/issues/298715 is complete.
    return false unless current_user.last_name.present?

    namespace.group? && (namespace.actual_plan_name == Plan::FREE || namespace.trial_active?)
  end

  def experiment_tracking_data_for_button_click(button_label)
    return {} unless Gitlab::Experimentation.active?(:contact_sales_btn_in_app)

    {
      track: {
        event: 'click_button',
        label: button_label,
        property: experiment_tracking_category_and_group(:contact_sales_btn_in_app)
      }
    }
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
    return false if namespace.free_personal?

    namespace.trial_active? || !(namespace.gold_plan? || namespace.ultimate_plan?)
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

  def upgrade_button_css_classes(namespace, plan, is_current_plan)
    css_classes = %w[btn btn-success gl-button]

    css_classes << 'disabled' if is_current_plan && !namespace.trial_active?
    css_classes << 'invisible' if ::Feature.enabled?(:hide_deprecated_billing_plans) && plan.deprecated?

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

  private

  def add_seats_url(group)
    return unless group

    "#{EE::SUBSCRIPTIONS_URL}/gitlab/namespaces/#{group.id}/extra_seats"
  end

  def plan_upgrade_url(group, plan)
    return unless group && plan&.id

    "#{EE::SUBSCRIPTIONS_URL}/gitlab/namespaces/#{group.id}/upgrade/#{plan.id}"
  end

  def plan_renew_url(group)
    return unless group

    "#{EE::SUBSCRIPTIONS_URL}/gitlab/namespaces/#{group.id}/renew"
  end

  def billable_seats_href(namespace)
    return unless namespace.group?

    group_seat_usage_path(namespace)
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
end

BillingPlansHelper.prepend_mod
