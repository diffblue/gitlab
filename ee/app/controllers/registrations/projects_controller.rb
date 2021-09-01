# frozen_string_literal: true

module Registrations
  class ProjectsController < ApplicationController
    include LearnGitlabHelper
    layout 'minimal'

    LEARN_GITLAB_TEMPLATE = 'learn_gitlab.tar.gz'
    LEARN_GITLAB_ULTIMATE_TEMPLATE = 'learn_gitlab_ultimate_trial.tar.gz'

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
        learn_gitlab_project = create_learn_gitlab_project

        experiment(:jobs_to_be_done, user: current_user)
          .track(:create_project, project: @project)

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

    def create_learn_gitlab_project
      File.open(learn_gitlab_template_path) do |archive|
        ::Projects::GitlabProjectsImportService.new(
          current_user,
          namespace_id: @project.namespace_id,
          file: archive,
          name: learn_gitlab_project_name
        ).execute
      end
    end

    def authorize_create_project!
      access_denied! unless can?(current_user, :create_projects, @namespace)
    end

    def set_namespace
      @namespace = Namespace.find_by_id(params[:namespace_id])
    end

    def project_params
      params.require(:project).permit(project_params_attributes)
    end

    def project_params_attributes
      [
        :namespace_id,
        :name,
        :path,
        :visibility_level
      ]
    end

    def learn_gitlab_project_name
      helpers.in_trial_onboarding_flow? ? s_('Learn GitLab - Ultimate trial') : s_('Learn GitLab')
    end

    def learn_gitlab_template_path
      file = if helpers.in_trial_onboarding_flow?
               LEARN_GITLAB_ULTIMATE_TEMPLATE
             else
               LEARN_GITLAB_TEMPLATE
             end

      Rails.root.join('vendor', 'project_templates', file)
    end
  end
end
