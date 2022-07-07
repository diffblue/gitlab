# frozen_string_literal: true

module Registrations
  class ProjectsController < ApplicationController
    include Registrations::CreateProject
    include OneTrustCSP
    include GoogleAnalyticsCSP

    layout 'minimal'

    before_action :check_if_gl_com_or_dev

    before_action only: [:new] do
      set_namespace
      authorize_create_project!
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end

    feature_category :onboarding

    def new
      @project = Project.new(namespace: @namespace)
    end

    def create
      @project = ::Projects::CreateService.new(current_user, project_params).execute

      if @project.saved?
        experiment(:combined_registration, user: current_user).track(:create_project, namespace: @project.namespace)

        @learn_gitlab_project = create_learn_gitlab_project

        if helpers.registration_verification_enabled?
          redirect_to new_users_sign_up_verification_path(url_params)
        elsif helpers.in_trial_onboarding_flow?
          redirect_to trial_getting_started_users_sign_up_welcome_path(url_params)
        else
          redirect_to continuous_onboarding_getting_started_users_sign_up_welcome_path(url_params)
        end
      else
        render :new
      end
    end

    private

    def authorize_create_project!
      access_denied! unless can?(current_user, :create_projects, @namespace)
    end

    def set_namespace
      @namespace = Namespace.find_by_id(params[:namespace_id])
    end

    def url_params
      if helpers.in_trial_onboarding_flow?
        { learn_gitlab_project_id: @learn_gitlab_project.id }
      else
        { project_id: @project.id }
      end
    end
  end
end

Registrations::ProjectsController.prepend_mod
