# frozen_string_literal: true

module Registrations
  class BaseNamespaceCreateService
    include BaseServiceUtility
    include Gitlab::Experiment::Dsl

    def initialize(user, params = {})
      @user = user
      @params = params.dup
    end

    private

    attr_reader :user, :params, :project, :group

    def after_successful_group_creation(group_track_action:)
      Gitlab::Tracking.event(self.class.name, group_track_action, namespace: group, user: user)
      Onboarding::Progress.onboard(group)

      unless params[:trial] == 'true'
        experiment(:automatic_trial_registration, actor: user).track(:assignment,
          namespace: group)
      end

      apply_trial if in_trial_onboarding_flow?
    end

    def modified_group_params
      return group_params unless group_needs_path_added?

      group_params.compact_blank.with_defaults(path: Namespace.clean_path(group_name))
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

    def group_needs_path_added?
      group_name.present? && group_path.blank?
    end

    def group_name
      params.dig(:group, :name)
    end

    def group_path
      params.dig(:group, :path)
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
