# frozen_string_literal: true

class Groups::BillingsController < Groups::ApplicationController
  include GitlabSubscriptions::SeatCountAlert

  before_action :verify_authorization
  before_action :verify_namespace_plan_check_enabled

  before_action only: [:index] do
    push_frontend_feature_flag(:refresh_billings_seats, type: :ops)
    push_frontend_feature_flag(:auditor_billing_page_access)
  end

  before_action only: :index do
    @seat_count_data = generate_seat_count_alert_data(@group)
  end

  layout 'group_settings'

  feature_category :purchase
  urgency :low

  def index
    @hide_search_settings = true
    @top_level_group = @group.root_ancestor if @group.has_parent?
    relevant_group = (@top_level_group || @group)
    current_plan = relevant_group.plan_name_for_upgrading
    @plans_data = GitlabSubscriptions::FetchSubscriptionPlansService
      .new(plan: current_plan, namespace_id: relevant_group.id)
      .execute

    unless @plans_data
      render 'shared/billings/customers_dot_unavailable'
    end
  end

  def refresh_seats
    if Feature.enabled?(:refresh_billings_seats, type: :ops)
      success = update_subscription_seats
    end

    if success
      render json: { success: true }
    else
      render json: { success: false }, status: :bad_request
    end
  end

  private

  def update_subscription_seats
    gitlab_subscription = group.gitlab_subscription

    return false unless gitlab_subscription

    gitlab_subscription.refresh_seat_attributes
    gitlab_subscription.save
  end

  def verify_authorization
    if Feature.enabled?(:auditor_billing_page_access, @group)
      authorize_billings_page!
    else
      authorize_admin_group!
    end
  end
end
