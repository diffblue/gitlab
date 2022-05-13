# frozen_string_literal: true

class Profiles::UsageQuotasController < Profiles::ApplicationController
  include OneTrustCSP

  feature_category :purchase
  urgency :low

  before_action only: [:index] do
    push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
  end

  def index
    @hide_search_settings = true
    @namespace = current_user.namespace
    @projects = @namespace.projects.with_shared_runners.page(params[:page])
  end
end
