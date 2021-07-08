# frozen_string_literal: true

class SubscriptionsController < ApplicationController
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
    return render_404 unless Feature.enabled?(:new_route_ci_minutes_purchase, default_enabled: :yaml)

    @group = find_group

    return render_404 if @group.nil?
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
    group = params[:selected_group] ? find_group : create_group

    return not_found if group.nil?
    return render json: group.errors.to_json unless group.persisted?

    response = Subscriptions::CreateService.new(
      current_user,
      group: group,
      customer_params: customer_params,
      subscription_params: subscription_params
    ).execute

    if response[:success]
      plan_id, quantity = subscription_params.values_at(:plan_id, :quantity)
      redirect_location = if params[:selected_group]
                            group_path(group, plan_id: plan_id, purchased_quantity: quantity)
                          else
                            edit_subscriptions_group_path(group.path, plan_id: plan_id, quantity: quantity, new_user: params[:new_user])
                          end

      response[:data] = { location: redirect_location }
    end

    render json: response[:data]
  end

  private

  def customer_params
    params.require(:customer).permit(:country, :address_1, :address_2, :city, :state, :zip_code, :company)
  end

  def subscription_params
    params.require(:subscription).permit(:plan_id, :payment_method_id, :quantity, :source)
  end

  def find_group
    selected_group = current_user.manageable_groups.top_most.find(params[:selected_group])

    result = GitlabSubscriptions::FilterPurchaseEligibleNamespacesService
      .new(user: current_user, namespaces: Array(selected_group))
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

  def customer_portal_new_subscription_url
    "#{EE::SUBSCRIPTIONS_URL}/subscriptions/new?plan_id=#{params[:plan_id]}&transaction=create_subscription"
  end

  def redirect_unauthenticated_user(from = action_name)
    return if current_user

    store_location_for :user, request.fullpath
    redirect_to new_user_registration_path(redirect_from: from)
  end

  def load_eligible_groups
    return unless current_user

    candidate_groups = current_user.manageable_groups.top_most.with_counts(archived: false)

    result = GitlabSubscriptions::FilterPurchaseEligibleNamespacesService
      .new(user: current_user, namespaces: candidate_groups)
      .execute

    @eligible_groups = result.success? ? result.payload : []
  end
end
