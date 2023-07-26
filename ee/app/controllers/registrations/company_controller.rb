# frozen_string_literal: true

module Registrations
  class CompanyController < ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP
    include RegistrationsTracking
    include ::Onboarding::SetRedirect

    layout 'minimal'

    before_action :check_if_gl_com_or_dev
    before_action :authenticate_user!
    feature_category :onboarding
    before_action only: [:new] do
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end

    helper_method :onboarding_status

    def new
      track_event('render')
    end

    def create
      result = GitlabSubscriptions::CreateTrialOrLeadService.new(user: current_user, params: permitted_params).execute

      if result.success?
        track_event('successfully_submitted_form')

        unless onboarding_status.trial?
          experiment(:automatic_trial_registration, actor: current_user).track(:successfully_submitted_form,
            label: tracking_label)
        end

        path = new_users_sign_up_group_path(redirect_params)
        save_onboarding_step_url(path, current_user)
        redirect_to path
      else
        flash.now[:alert] = result.errors.to_sentence
        render :new, status: :unprocessable_entity
      end
    end

    private

    def permitted_params
      params.permit(
        :company_name,
        :company_size,
        :first_name,
        :last_name,
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
      # Pass through trial param for automatic_trial_registration experiment
      # to exclude user that comes from trial registration
      base_params = glm_tracking_params.merge(trial: params[:trial])

      return base_params unless params[:trial_onboarding_flow] == 'true'

      base_params.merge(trial_onboarding_flow: true)
    end

    def track_event(action)
      ::Gitlab::Tracking.event(self.class.name, action, user: current_user, label: tracking_label)
    end

    def tracking_label
      return 'trial_registration' if onboarding_status.trial?

      'free_registration'
    end

    def onboarding_status
      ::Onboarding::Status.new(params.to_unsafe_h.deep_symbolize_keys, session, current_user)
    end
    strong_memoize_attr :onboarding_status
  end
end
