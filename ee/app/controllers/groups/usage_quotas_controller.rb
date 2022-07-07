# frozen_string_literal: true

class Groups::UsageQuotasController < Groups::ApplicationController
  include OneTrustCSP
  include GoogleAnalyticsCSP
  include GitlabSubscriptions::SeatCountAlert

  before_action :authorize_admin_group!
  before_action :verify_usage_quotas_enabled!
  before_action :push_free_user_cap_feature_flags, only: :index
  before_action :push_usage_quotas_pipelines_vue, only: :index

  before_action only: [:index] do
    @seat_count_data = generate_seat_count_alert_data(@group)
  end

  layout 'group_settings'

  feature_category :purchase
  urgency :low

  def index
    @hide_search_settings = true
    @current_namespace_usage = Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: @group.id)
    @projects_usage = Ci::Minutes::ProjectMonthlyUsage
                        .for_namespace_monthly_usage(@current_namespace_usage)
                        .page(params[:page])
  end

  def pending_members
    render_404 unless @group.apply_user_cap?
    @hide_search_settings = true
  end

  private

  def verify_usage_quotas_enabled!
    render_404 unless License.feature_available?(:usage_quotas)
    render_404 if @group.has_parent?
  end

  def push_free_user_cap_feature_flags
    push_frontend_feature_flag(:free_user_cap, @group)
    push_frontend_feature_flag(:preview_free_user_cap, @group)
  end

  def push_usage_quotas_pipelines_vue
    push_frontend_feature_flag(:usage_quotas_pipelines_vue, @group)
  end
end
