# frozen_string_literal: true

class Groups::BillingsController < Groups::ApplicationController
  before_action :authorize_admin_group!
  before_action :verify_namespace_plan_check_enabled

  before_action only: [:index] do
    push_frontend_feature_flag(:refresh_billings_seats, type: :ops, default_enabled: :yaml)
  end

  layout 'group_settings'

  feature_category :purchase

  def index
    @hide_search_settings = true
    @top_most_group = @group.root_ancestor if @group.has_parent?
    relevant_group = (@top_most_group || @group)
    current_plan = relevant_group.plan_name_for_upgrading
    @plans_data = GitlabSubscriptions::FetchSubscriptionPlansService
      .new(plan: current_plan, namespace_id: relevant_group.id)
      .execute

    if @plans_data
      track_from_side_nav(relevant_group)
    else
      render 'shared/billings/customers_dot_unavailable'
    end
  end

  def refresh_seats
    if Feature.enabled?(:refresh_billings_seats, type: :ops, default_enabled: :yaml)
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

    gitlab_subscription.refresh_seat_attributes!
    gitlab_subscription.save
  end

  def track_from_side_nav(relevant_group)
    return unless helpers.accessed_billing_from_side_nav?

    experiment(:billing_in_side_nav, actor: current_user, namespace: relevant_group, sticky_to: current_user).track(:view, label: 'view_billing')
  end
end
