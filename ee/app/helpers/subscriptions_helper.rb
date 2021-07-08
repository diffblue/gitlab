# frozen_string_literal: true

module SubscriptionsHelper
  include ::Gitlab::Utils::StrongMemoize

  def subscription_data(eligible_groups)
    {
      setup_for_company: (current_user.setup_for_company == true).to_s,
      full_name: current_user.name,
      available_plans: subscription_available_plans.to_json,
      plan_id: params[:plan_id],
      namespace_id: params[:namespace_id],
      new_user: new_user?.to_s,
      group_data: present_groups(eligible_groups).to_json,
      source: params[:source]
    }
  end

  def addon_data(group)
    {
      group_data: [present_group(group)].to_json,
      namespace_id: params[:selected_group],
      source: params[:source]
    }
  end

  def plan_title
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
      .map { |plan_data| plan_data.slice(:id, :code, :price_per_year, :deprecated, :name, :hide_card) }
  end

  def subscription_available_plans
    return plans_data unless ::Feature.enabled?(:hide_deprecated_billing_plans)

    plans_data.reject { |plan_data| plan_data[:deprecated] || plan_data[:hide_card] }
  end

  def present_groups(groups)
    groups.map { |namespace| present_group(namespace) }
  end

  def present_group(namespace)
    {
      id: namespace.id,
      name: namespace.name,
      users: namespace.member_count,
      guests: namespace.guest_count
    }
  end
end
