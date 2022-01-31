# frozen_string_literal: true

class SubscriptionsController < ApplicationController
  include InternalRedirect
  include OneTrustCSP

  layout 'checkout'
  skip_before_action :authenticate_user!, only: [:new]

  before_action :load_eligible_groups, only: :new

  before_action only: [:new] do
    push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
  end

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

    # At the moment of this comment the account id is directly available to the view.
    # This might change in the future given the intention to associate the account id to the namespace.
    # See: https://gitlab.com/gitlab-org/gitlab/-/issues/338546#note_684762160
    result = find_group(plan_id: ci_minutes_plan_data["id"])
    @group = result[:namespace]
    @account_id = result[:account_id]
    @active_subscription = result[:active_subscription]

    return render_404 if @group.nil?

    render_404 unless Feature.enabled?(:new_route_ci_minutes_purchase, @group, default_enabled: :yaml)
  end

  def buy_storage
    return render_404 unless storage_plan_data.present?

    # At the moment of this comment the account id is directly available to the view.
    # This might change in the future given the intention to associate the account id to the namespace.
    # See: https://gitlab.com/gitlab-org/gitlab/-/issues/338546#note_684762160
    result = find_group(plan_id: storage_plan_data["id"])
    @group = result[:namespace]
    @account_id = result[:account_id]
    @active_subscription = result[:active_subscription]

    return render_404 if @group.nil?

    render_404 unless Feature.enabled?(:new_route_storage_purchase, @group, default_enabled: :yaml)
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
    group = params[:selected_group] ? current_group : create_group

    return not_found if group.nil?

    unless group.persisted?
      track_purchase message: group.errors.full_messages.to_s
      return render json: group.errors.to_json
    end

    response = Subscriptions::CreateService.new(
      current_user,
      group: group,
      customer_params: customer_params,
      subscription_params: subscription_params
    ).execute

    if response[:success]
      track_purchase message: 'Success', namespace: group
      response[:data] = { location: redirect_location(group) }
    else
      track_purchase message: response.dig(:data, :errors), namespace: group
    end

    render json: response[:data]
  end

  private

  def track_purchase(message:, namespace: nil)
    Gitlab::Tracking.event(self.class.name, 'click_button',
                           label: 'confirm_purchase',
                           property: message,
                           user: current_user,
                           namespace: namespace
    )
  end

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
    params.require(:subscription).permit(:plan_id, :is_addon, :payment_method_id, :quantity, :source).merge(params.permit(:active_subscription))
  end

  def find_group(plan_id:)
    selected_group = current_user.manageable_groups.top_most.find(params[:selected_group])

    result = GitlabSubscriptions::FetchPurchaseEligibleNamespacesService
      .new(user: current_user, plan_id: plan_id, namespaces: Array(selected_group))
      .execute

    return {} unless result.success?

    result.payload.first || {}
  end

  def current_group
    find_group(plan_id: subscription_params[:plan_id]).dig(:namespace)
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

  def storage_plan_data
    strong_memoize(:storage_plan_data) do
      plan_response = client.get_plans(tags: ['STORAGE_PLAN'])

      plan_response[:success] ? plan_response[:data].first : nil
    end
  end

  def load_eligible_groups
    return @eligible_groups = [] unless current_user

    @eligible_groups = fetch_eligible_groups
  end

  def fetch_eligible_groups
    candidate_groups = current_user.manageable_groups.top_most.with_counts(archived: false)
    result = GitlabSubscriptions::FetchPurchaseEligibleNamespacesService
               .new(user: current_user, namespaces: candidate_groups, any_self_service_plan: true)
               .execute

    return [] unless result.success?

    (result.payload || []).map { |h| h.dig(:namespace) }
  end
end
