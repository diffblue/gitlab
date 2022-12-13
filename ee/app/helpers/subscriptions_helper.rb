# frozen_string_literal: true

module SubscriptionsHelper
  include ::Gitlab::Utils::StrongMemoize

  def subscription_data(eligible_groups)
    {
      setup_for_company: current_user.setup_for_company.to_s,
      full_name: current_user.name,
      available_plans: subscription_available_plans.to_json,
      plan_id: params[:plan_id],
      namespace_id: params[:namespace_id],
      new_user: new_user?.to_s,
      group_data: present_groups(eligible_groups).to_json,
      source: params[:source],
      trial: current_user.namespace.trial?.to_s,
      new_trial_registration_path: new_trial_registration_path
    }
  end

  def buy_addon_data(group, account_id, active_subscription, anchor, purchased_product)
    {
      active_subscription: active_subscription,
      group_data: [present_group(group, account_id)].to_json,
      namespace_id: params[:selected_group],
      redirect_after_success: group_usage_quotas_path(group, anchor: anchor, purchased_product: purchased_product),
      source: params[:source]
    }
  end

  def plan_title
    return if params[:plan_id].blank?

    strong_memoize(:plan_title) do
      plan = subscription_available_plans.find { |plan| plan[:id] == params[:plan_id] }
      plan[:code].titleize if plan
    end
  end

  private

  def new_user?
    return false unless request.referer.present?

    URI.parse(request.referer).path == users_sign_up_welcome_path
  end

  def plans_data
    GitlabSubscriptions::FetchSubscriptionPlansService.new(plan: :free).execute
      .map(&:symbolize_keys)
      .reject { |plan_data| plan_data[:free] }
      .map do |plan_data|
        plan_data.slice(
          :id,
          :code,
          :price_per_year,
          :eligible_to_use_promo_code,
          :deprecated,
          :name,
          :hide_card
        )
      end
  end

  def subscription_available_plans
    return plans_data unless ::Feature.enabled?(:hide_deprecated_billing_plans)

    plans_data.reject { |plan_data| plan_data[:deprecated] || plan_data[:hide_card] }
  end

  def present_groups(groups)
    groups.map { |namespace| present_group(namespace) }
  end

  def present_group(namespace, account_id = nil)
    {
      id: namespace.id,
      account_id: account_id,
      name: namespace.name,
      full_path: namespace.full_path
    }
  end
end
