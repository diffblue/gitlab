# frozen_string_literal: true

# EE:SaaS
module Subscriptions
  class TrialsController < ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP
    include RegistrationsTracking

    layout 'minimal'

    skip_before_action :set_confirm_warning
    before_action :check_if_gl_com_or_dev
    before_action :authenticate_user!
    before_action only: :new do
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end

    feature_category :purchase
    urgency :low

    def new
      if params[:step] == GitlabSubscriptions::Trials::CreateService::TRIAL
        render :step_namespace
      else
        render :step_lead
      end
    end

    def create
      @result = GitlabSubscriptions::Trials::CreateService.new(
        step: params[:step], lead_params: lead_params, trial_params: trial_params, user: current_user
      ).execute

      if @result.success?
        # lead and trial created
        redirect_to trial_success_path(@result.payload[:namespace])
      elsif @result.reason == GitlabSubscriptions::Trials::CreateService::NO_SINGLE_NAMESPACE
        # lead created, but we now need to select namespace and then apply a trial
        redirect_to new_trial_path(@result.payload[:trial_selection_params])
      elsif @result.reason == GitlabSubscriptions::Trials::CreateService::NOT_FOUND
        # namespace not found/not permitted to create
        render_404
      elsif @result.reason == GitlabSubscriptions::Trials::CreateService::LEAD_FAILED
        render :step_lead_failed
      elsif @result.reason == GitlabSubscriptions::Trials::CreateService::NAMESPACE_CREATE_FAILED
        # namespace creation failed
        params[:namespace_id] = @result.payload[:namespace_id]

        render :step_namespace_failed
      else
        # trial creation failed
        params[:namespace_id] = @result.payload[:namespace_id]

        render :trial_failed
      end
    end

    private

    def trial_success_path(namespace)
      if discover_group_security_flow?
        group_security_dashboard_path(namespace, { trial: true })
      else
        stored_location_or_provided_path(group_path(namespace, { trial: true }))
      end
    end

    def stored_location_or_provided_path(path)
      if current_user.setup_for_company
        stored_location_for(:user) || path
      else
        path
      end
    end

    def authenticate_user!
      return if current_user

      redirect_to new_trial_registration_path(glm_tracking_params), alert: I18n.t('devise.failure.unauthenticated')
    end

    def lead_params
      params.permit(
        :company_name, :company_size, :first_name, :last_name, :phone_number,
        :country, :state, :website_url, :glm_content, :glm_source
      ).to_h
    end

    def trial_params
      params.permit(:new_group_name, :namespace_id, :trial_entity, :glm_source, :glm_content).to_h
    end

    def discover_group_security_flow?
      %w[discover-group-security discover-project-security].include?(params[:glm_content])
    end
  end
end

Subscriptions::TrialsController.prepend_mod
