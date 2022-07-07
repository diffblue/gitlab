# frozen_string_literal: true

module EE
  module Registrations
    module WelcomeController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override
      include ::Gitlab::Utils::StrongMemoize

      TRIAL_ONBOARDING_BOARD_NAME = 'GitLab onboarding'

      prepended do
        include OneTrustCSP
        include GoogleAnalyticsCSP

        before_action :authorized_for_trial_onboarding!,
                      only: [
                        :trial_getting_started,
                        :trial_onboarding_board
                      ]

        before_action only: :show do
          publish_combined_registration_experiment
        end

        before_action only: [:trial_getting_started] do
          push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
        end
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

        cookies[:confetti_post_signup] = true

        render locals: { project: project }
      end

      private

      def show_company_form?
        update_params[:setup_for_company] == 'true' &&
          ::Feature.enabled?(:about_your_company_registration_flow)
      end

      override :update_params
      def update_params
        clean_params = super.merge(params.require(:user).permit(:email_opted_in, :registration_objective))

        return clean_params unless ::Gitlab.com?

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

      def publish_combined_registration_experiment
        combined_registration_experiment.publish if show_signup_onboarding?
      end

      def combined_registration_experiment
        experiment(:combined_registration, user: current_user)
      end

      def passed_through_params
        update_params.slice(:role, :registration_objective).merge(params.permit(:jobs_to_be_done_other))
      end

      override :update_success_path
      def update_success_path
        if params[:joining_project] == 'true'
          path_for_signed_in_user(current_user)
        else
          if show_company_form?
            new_users_sign_up_company_path(passed_through_params)
          else
            experiment(:combined_registration, user: current_user).redirect_path
          end
        end
      end

      override :path_for_signed_in_user
      def path_for_signed_in_user(user)
        return users_almost_there_path(email: user.email) if requires_confirmation?(user)

        stored_url = stored_location_for(user)
        if ::Feature.enabled?(:about_your_company_registration_flow) &&
            stored_url&.include?(new_users_sign_up_company_path)
          company_params = update_params.slice(:role, :other_role, :registration_objective)
                            .merge(params.permit(:jobs_to_be_done_other))
          redirect_uri = ::Gitlab::Utils.add_url_parameters(stored_url, company_params)
          store_location_for(:user, redirect_uri)
        else
          stored_url || members_activity_path(user.members)
        end
      end
    end
  end
end
