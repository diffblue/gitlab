# frozen_string_literal: true

module Registrations
  class CompanyController < ApplicationController
    layout 'minimal'

    before_action :check_if_gl_com_or_dev
    before_action :authenticate_user!
    feature_category :onboarding

    def new
    end

    def create
      result = GitlabSubscriptions::CreateTrialOrLeadService.new.execute(
        user: current_user,
        params: permitted_params
      )

      if result[:success]
        redirect_to new_users_sign_up_groups_project_path(redirect_param)
      else
        render :new
      end
    end

    private

    def authenticate_user!
      return if current_user

      redirect_to new_trial_registration_path, alert: I18n.t('devise.failure.unauthenticated')
    end

    def permitted_params
      params.permit(
        :company_name,
        :company_size,
        :phone_number,
        :country,
        :state,
        :website_url,
        # previous step(s) data
        :role,
        :jtbd,
        :comment,
        :trial
      )
    end

    def redirect_param
      if params[:trial] == 'true'
        { trial_onboarding_flow: true }
      else
        { skip_trial: true }
      end
    end
  end
end
