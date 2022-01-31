# frozen_string_literal: true

module Registrations::CreateProject
  extend ActiveSupport::Concern
  include LearnGitlabHelper

  LEARN_GITLAB_ULTIMATE_TEMPLATE = 'learn_gitlab_ultimate.tar.gz'

  included do
    private

    def learn_gitlab_template_path
      Rails.root.join('vendor', 'project_templates', LEARN_GITLAB_ULTIMATE_TEMPLATE)
    end

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

    def learn_gitlab_project_name
      helpers.in_trial_onboarding_flow? ? LearnGitlab::Project::PROJECT_NAME_ULTIMATE_TRIAL : LearnGitlab::Project::PROJECT_NAME
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
  end
end
