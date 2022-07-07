# frozen_string_literal: true

class Profiles::UsageQuotasController < Profiles::ApplicationController
  include OneTrustCSP
  include GoogleAnalyticsCSP

  feature_category :purchase
  urgency :low

  before_action :push_feature_flags, only: :index

  def index
    @hide_search_settings = true
    @namespace = current_user.namespace
    @current_namespace_usage = Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: @namespace.id)
    @projects_usage = Ci::Minutes::ProjectMonthlyUsage
                        .for_namespace_monthly_usage(@current_namespace_usage)
                        .page(params[:page])
  end

  private

  def push_feature_flags
    push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    push_frontend_feature_flag(:usage_quotas_pipelines_vue, @group)
  end
end
