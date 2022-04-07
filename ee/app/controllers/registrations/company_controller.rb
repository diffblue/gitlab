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
      if Gitlab::Utils.to_boolean(params[:trial])
        result = GitlabSubscriptions::CreateLeadService.new.execute({ trial_user: company_params })
        redirect_to(new_users_sign_up_groups_project_path(trial_onboarding_flow: true)) && return if result[:success]
      else
        result = GitlabSubscriptions::CreateHandRaiseLeadService.new.execute(company_params)
        redirect_to(new_users_sign_up_groups_project_path(skip_trial: true)) && return if result[:success]
      end

      render :new
    end

    private

    def authenticate_user!
      return if current_user

      redirect_to new_trial_registration_path, alert: I18n.t('devise.failure.unauthenticated')
    end

    def company_params
      params.permit(:first_name, :last_name, :company_name, :company_size, :phone_number,
                    :country, :state, :website_url, :glm_content, :glm_source)
            .merge(extra_params)
    end

    def extra_params
      {
        work_email: current_user.email,
        uid: current_user.id,
        provider: 'gitlab',
        setup_for_company: current_user.setup_for_company,
        skip_email_confirmation: true,
        gitlab_com_trial: true,
        newsletter_segment: current_user.email_opted_in
      }
    end
  end
end
