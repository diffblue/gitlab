# frozen_string_literal: true

module Registrations
  class ProjectsController < ApplicationController
    include Registrations::CreateProject
    layout 'minimal'

    before_action :check_if_gl_com_or_dev

    before_action only: [:new] do
      set_namespace
      authorize_create_project!
    end

    feature_category :onboarding

    def new
      @project = Project.new(namespace: @namespace)
    end

    def create
      @project = ::Projects::CreateService.new(current_user, project_params).execute

      if @project.saved?
        experiment(:combined_registration, user: current_user).track(:create_project, namespace: @project.namespace)

        learn_gitlab_project = create_learn_gitlab_project

        experiment(:force_company_trial, user: current_user)
          .track(:create_project, namespace: @project.namespace, project: @project, user: current_user)

        if helpers.in_trial_onboarding_flow?
          redirect_to trial_getting_started_users_sign_up_welcome_path(learn_gitlab_project_id: learn_gitlab_project.id)
        else
          redirect_to continuous_onboarding_getting_started_users_sign_up_welcome_path(project_id: @project.id)
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
  end
end
