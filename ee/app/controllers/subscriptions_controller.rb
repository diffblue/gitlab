# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  include InternalRedirect

  layout 'checkout'
  skip_before_action :authenticate_user!, only: [:new]

  before_action :load_eligible_groups, only: :new

  feature_category :purchase

  content_security_policy do |p|
    next if p.directives.blank?

    default_script_src = p.directives['script-src'] || p.directives['default-src']
    script_src_values = Array.wrap(default_script_src) | ["'self'", "'unsafe-eval'", 'https://*.zuora.com']

    default_frame_src = p.directives['frame-src'] || p.directives['default-src']
    frame_src_values = Array.wrap(default_frame_src) | ["'self'", 'https://*.zuora.com']

    default_child_src = p.directives['child-src'] || p.directives['default-src']
    child_src_values = Array.wrap(default_child_src) | ["'self'", 'https://*.zuora.com']

    p.script_src(*script_src_values)
    p.frame_src(*frame_src_values)
    p.child_src(*child_src_values)
  end

  def new
    redirect_unauthenticated_user('checkout')
  end

  def buy_minutes
    return render_404 unless ci_minutes_plan_data.present?

    @group = find_group(plan_id: ci_minutes_plan_data["id"])

    return render_404 if @group.nil?

    render_404 unless Feature.enabled?(:new_route_ci_minutes_purchase, @group, default_enabled: :yaml)
  end

  def payment_form
    response = client.payment_form_params(params[:id])
    render json: response[:data]
  end

  def payment_method
    response = client.payment_method(params[:id])
    render json: response[:data]
  end

  def create
    current_user.update(setup_for_company: true) if params[:setup_for_company]
    group = params[:selected_group] ? find_group(plan_id: subscription_params[:plan_id]) : create_group

    return not_found if group.nil?
    return render json: group.errors.to_json unless group.persisted?

    response = Subscriptions::CreateService.new(
      current_user,
      group: group,
      customer_params: customer_params,
      subscription_params: subscription_params
    ).execute

    if response[:success]
      experiment(:force_company_trial, user: current_user).track(:create_subscription, namespace: group, user: current_user)
      response[:data] = { location: redirect_location(group) }
    end

    render json: response[:data]
  end

  private

  def redirect_location(group)
    return safe_redirect_path(params[:redirect_after_success]) if params[:redirect_after_success]

    plan_id, quantity = subscription_params.values_at(:plan_id, :quantity)
    return group_path(group, plan_id: plan_id, purchased_quantity: quantity) if params[:selected_group]

    edit_subscriptions_group_path(group.path, plan_id: plan_id, quantity: quantity, new_user: params[:new_user])
  end

  def customer_params
    params.require(:customer).permit(:country, :address_1, :address_2, :city, :state, :zip_code, :company)
  end

  def subscription_params
    params.require(:subscription).permit(:plan_id, :payment_method_id, :quantity, :source)
  end

  def find_group(plan_id:)
    selected_group = current_user.manageable_groups.top_most.find(params[:selected_group])

    result = GitlabSubscriptions::FilterPurchaseEligibleNamespacesService
      .new(user: current_user, plan_id: plan_id, namespaces: Array(selected_group))
      .execute

    result.success? ? result.payload.first : nil
  end

  def create_group
    name = Namespace.clean_name(params[:setup_for_company] ? customer_params[:company] : current_user.name)
    path = Namespace.clean_path(name)

    Groups::CreateService.new(current_user, name: name, path: path).execute
  end

  def client
    Gitlab::SubscriptionPortal::Client
  end

  def redirect_unauthenticated_user(from = action_name)
    return if current_user

    store_location_for :user, request.fullpath
    redirect_to new_user_registration_path(redirect_from: from)
  end

  def ci_minutes_plan_data
    strong_memoize(:ci_minutes_plan_data) do
      plan_response = client.get_plans(tags: ['CI_1000_MINUTES_PLAN'])

      plan_response[:success] ? plan_response[:data].first : nil
    end
  end

  def load_eligible_groups
    return @eligible_groups = [] unless current_user

    candidate_groups = current_user.manageable_groups.top_most.with_counts(archived: false)

    result = GitlabSubscriptions::FilterPurchaseEligibleNamespacesService
      .new(user: current_user, namespaces: candidate_groups, any_self_service_plan: true)
      .execute

    @eligible_groups = result.success? ? result.payload : []
  end
end
