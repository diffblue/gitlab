# frozen_string_literal: true

module Registrations
  class CompanyController < ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP
    include RegistrationsTracking

    layout 'minimal'

    before_action :check_if_gl_com_or_dev
    before_action :authenticate_user!
    feature_category :onboarding
    before_action only: [:new] do
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end

    def new
    end

    def create
      result = GitlabSubscriptions::CreateTrialOrLeadService.new(user: current_user, params: permitted_params).execute

      if result.success?
        redirect_to new_users_sign_up_groups_project_path(redirect_params)
      else
        flash.now[:alert] = result[:message]
        render :new, status: result.http_status
      end
    end

    private

    def permitted_params
      params.permit(
        :company_name,
        :company_size,
        :phone_number,
        :country,
        :state,
        :website_url,
        # passed through params
        :role,
        :registration_objective,
        :jobs_to_be_done_other,
        :trial_onboarding_flow
      ).merge(glm_tracking_params)
    end

    def redirect_params
      return glm_tracking_params unless params[:trial_onboarding_flow] == 'true'

      glm_tracking_params.merge(trial_onboarding_flow: true)
    end
  end
end
