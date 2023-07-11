# frozen_string_literal: true

module EE
  module Registrations
    module WelcomeController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        include OneTrustCSP
        include GoogleAnalyticsCSP
        include Onboarding::SetRedirect
        include RegistrationsTracking

        before_action only: :show do
          push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
        end
      end

      private

      def redirect_to_company_form?
        update_params[:setup_for_company] == 'true' || helpers.trial_selected?
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

      override :complete_signup_onboarding?
      def complete_signup_onboarding?
        !helpers.in_subscription_flow? &&
          !helpers.user_has_memberships? &&
          !helpers.in_oauth_flow? &&
          helpers.signup_onboarding_enabled?
      end

      def passed_through_params
        pass_through = update_params.slice(:role, :registration_objective)
                     .merge(params.permit(:jobs_to_be_done_other))
                     .merge(glm_tracking_params)

        pass_through[:trial] = params[:trial] if ::Gitlab.com?

        pass_through
      end

      def iterable_params
        {
          provider: 'gitlab',
          work_email: current_user.email,
          uid: current_user.id,
          comment: params[:jobs_to_be_done_other],
          jtbd: update_params[:registration_objective],
          product_interaction: iterable_product_interaction
        }.merge(update_params.slice(:setup_for_company, :role).to_h.symbolize_keys)
      end

      def iterable_product_interaction
        if helpers.user_has_memberships?
          'Invited User'
        else
          'Personal SaaS Registration'
        end
      end

      def free_personal_registration_or_invite?
        return false if helpers.trial_selected? # skip trial
        return true if helpers.user_has_memberships? # invited
        # skip company page because it already sends request to CustomersDot
        return false if redirect_to_company_form?

        # regular registration on .com
        complete_signup_onboarding?
      end

      override :successful_update_hooks
      def successful_update_hooks
        finish_onboarding(current_user) unless complete_signup_onboarding?

        return unless free_personal_registration_or_invite?

        Onboarding::CreateIterableTriggerWorker.perform_async(iterable_params)
      end

      override :signup_onboarding_path
      def signup_onboarding_path
        if params[:joining_project] == 'true'
          finish_onboarding(current_user)
          path_for_signed_in_user(current_user)
        elsif redirect_to_company_form?
          path = new_users_sign_up_company_path(passed_through_params)
          save_onboarding_step_url(path, current_user)
          path
        else
          path = new_users_sign_up_group_path
          save_onboarding_step_url(path, current_user)
          path
        end
      end

      override :track_event
      def track_event(action, label = tracking_label)
        ::Gitlab::Tracking.event(
          helpers.body_data_page,
          action,
          user: current_user,
          label: label
        )
      end

      def tracking_label
        return 'trial_registration' if helpers.trial_selected?
        return 'invite_registration' if helpers.user_has_memberships?

        'free_registration'
      end

      override :welcome_update_params
      def welcome_update_params
        glm_tracking_params
      end
    end
  end
end
