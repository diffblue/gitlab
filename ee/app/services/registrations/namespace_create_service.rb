# frozen_string_literal: true

module Registrations
  class NamespaceCreateService
    include BaseServiceUtility
    include Gitlab::Experiment::Dsl

    attr_reader :project, :group

    def initialize(user, params = {})
      @user = user
      @params = params.dup
    end

    def execute
      if new_group?
        create_with_new_group_flow
      else
        @group = Group.find_by_id(existing_group_id)

        create_project_flow
      end
    end

    private

    LEARN_GITLAB_ULTIMATE_TEMPLATE = 'learn_gitlab_ultimate.tar.gz'

    attr_reader :user, :params

    def new_group?
      !existing_group_id
    end

    def existing_group_id
      params.dig(:group, :id)
    end

    def create_with_new_group_flow
      @group = Groups::CreateService.new(user, modified_group_params).execute

      if group.persisted?
        Gitlab::Tracking.event(self.class.name, 'create_group', namespace: group, user: user)
        require_verification_experiment.record_conversion(group)

        apply_trial if in_trial_onboarding_flow?

        create_project_flow
      else
        @project = Project.new(project_params)

        ServiceResponse.error(message: 'Group failed to be created')
      end
    end

    def modified_group_params
      group_name = params.dig(:group, :name)
      modifed_group_params = group_params
      if group_name.present? && params.dig(:group, :path).blank?
        modifed_group_params = modifed_group_params.compact_blank.with_defaults(path: Namespace.clean_path(group_name))
      end

      modifed_group_params
    end

    def require_verification_experiment
      experiment(:require_verification_for_namespace_creation, user: user)
    end

    def in_trial_onboarding_flow?
      params[:trial_onboarding_flow] == 'true'
    end

    def apply_trial
      trial_user_information = glm_params.merge({
                                                  namespace_id: group.id,
                                                  gitlab_com_trial: true,
                                                  sync_to_gl: true
                                                })

      GitlabSubscriptions::Trials::ApplyTrialWorker.perform_async(user.id, trial_user_information.to_h)
    end

    def glm_params
      params.permit(:glm_source, :glm_content)
    end

    def create_project_params
      project_params(:initialize_with_readme)
    end

    def project_params(*extra)
      params.require(:project).permit(project_params_attributes + extra).merge(namespace_id: group.id)
    end

    def project_params_attributes
      [
        :namespace_id,
        :name,
        :path,
        :visibility_level
      ]
    end

    def create_project_flow
      @project = ::Projects::CreateService.new(user, create_project_params).execute

      if project.persisted?
        Gitlab::Tracking.event(self.class.name, 'create_project', namespace: project.namespace, user: user)

        create_learn_gitlab_project

        ServiceResponse.success
      else
        ServiceResponse.error(message: 'Project failed to be created')
      end
    end

    def create_learn_gitlab_project
      ::Onboarding::CreateLearnGitlabWorker.perform_async(learn_gitlab_template_path,
                                                          learn_gitlab_project_name,
                                                          project.namespace_id,
                                                          user.id)
    end

    def learn_gitlab_template_path
      Rails.root.join('vendor', 'project_templates', LEARN_GITLAB_ULTIMATE_TEMPLATE)
    end

    def learn_gitlab_project_name
      if in_trial_onboarding_flow?
        Onboarding::LearnGitlab::PROJECT_NAME_ULTIMATE_TRIAL
      else
        Onboarding::LearnGitlab::PROJECT_NAME
      end
    end

    def group_params
      params.require(:group).permit(
        :name,
        :path,
        :visibility_level
      ).merge(
        create_event: true,
        setup_for_company: user.setup_for_company
      )
    end
  end
end
