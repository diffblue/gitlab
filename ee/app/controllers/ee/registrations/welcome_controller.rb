# frozen_string_literal: true

module EE
  module Registrations
    module WelcomeController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      TRIAL_ONBOARDING_BOARD_NAME = 'GitLab onboarding'

      prepended do
        before_action :authorized_for_trial_onboarding!,
                      only: [
                        :trial_getting_started,
                        :trial_onboarding_board
                      ]
      end

      def trial_getting_started
        render locals: { learn_gitlab_project: learn_gitlab_project }
      end

      def trial_onboarding_board
        board = learn_gitlab_project.boards.find_by_name(TRIAL_ONBOARDING_BOARD_NAME)
        path = board ? project_board_path(learn_gitlab_project, board) : project_boards_path(learn_gitlab_project)
        redirect_to path
      end

      def continuous_onboarding_getting_started
        project = ::Project.find(params[:project_id])
        return access_denied! unless can?(current_user, :owner_access, project)

        render locals: { project: project }
      end

      private

      override :update_params
      def update_params
        clean_params = super.merge(params.require(:user).permit(:email_opted_in))

        return clean_params unless ::Gitlab.dev_env_or_com?

        clean_params[:email_opted_in] = '1' if clean_params[:setup_for_company] == 'true'

        if clean_params[:email_opted_in] == '1'
          clean_params[:email_opted_in_ip] = request.remote_ip
          clean_params[:email_opted_in_source_id] = User::EMAIL_OPT_IN_SOURCE_ID_GITLAB_COM
          clean_params[:email_opted_in_at] = Time.zone.now
        end

        clean_params
      end

      override :show_signup_onboarding?
      def show_signup_onboarding?
        !helpers.in_subscription_flow? &&
          !helpers.user_has_memberships? &&
          !helpers.in_oauth_flow? &&
          !helpers.in_trial_flow? &&
          helpers.signup_onboarding_enabled?
      end

      def authorized_for_trial_onboarding!
        access_denied! unless can?(current_user, :owner_access, learn_gitlab_project)
      end

      def learn_gitlab_project
        strong_memoize(:learn_gitlab_project) do
          ::Project.find(params[:learn_gitlab_project_id])
        end
      end
    end
  end
end
