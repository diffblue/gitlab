# frozen_string_literal: true

module Registrations
  class WelcomeController < ApplicationController
    include OneTrustCSP
    include GoogleAnalyticsCSP
    include GoogleSyndicationCSP
    include ::Gitlab::Utils::StrongMemoize
    include ::Onboarding::Redirectable
    include ::Onboarding::SetRedirect
    include RegistrationsTracking

    layout 'minimal'

    before_action :check_if_gl_com_or_dev
    before_action only: :show do
      push_frontend_feature_flag(:gitlab_gtm_datalayer, type: :ops)
    end

    helper_method :onboarding_status

    feature_category :user_management

    def show
      return redirect_to path_for_signed_in_user if completed_welcome_step?

      track_event('render')
    end

    def update
      result = ::Users::SignupService.new(current_user, update_params).execute

      if result.success?
        track_event('successfully_submitted_form')
        successful_update_hooks

        redirect_to update_success_path
      else
        render :show
      end
    end

    private

    def authenticate_user!
      return if current_user

      redirect_to new_user_registration_path
    end

    def completed_welcome_step?
      !current_user.setup_for_company.nil?
    end

    def update_params
      params.require(:user).permit(:role, :setup_for_company, :registration_objective)
    end

    def passed_through_params
      opt_in_param = {
        opt_in: ::Gitlab::Utils.to_boolean(params[:opt_in_to_email], default: onboarding_status.setup_for_company?)
      }

      update_params.slice(:role, :registration_objective)
                   .merge(params.permit(:jobs_to_be_done_other))
                   .merge(glm_tracking_params)
                   .merge(params.permit(:trial))
                   .merge(opt_in_param)
    end

    def iterable_params
      {
        provider: 'gitlab',
        work_email: current_user.email,
        uid: current_user.id,
        comment: params[:jobs_to_be_done_other],
        jtbd: update_params[:registration_objective],
        product_interaction: onboarding_status.iterable_product_interaction,
        opt_in: ::Gitlab::Utils.to_boolean(params[:opt_in_to_email], default: false)
      }.merge(update_params.slice(:setup_for_company, :role).to_h.symbolize_keys)
    end

    def update_success_path
      if onboarding_status.continue_full_onboarding? # trials/regular registration on .com
        signup_onboarding_path
      elsif onboarding_status.single_invite? # invites w/o tasks due to order
        flash[:notice] = helpers.invite_accepted_notice(onboarding_status.last_invited_member)
        onboarding_status.last_invited_member_source.activity_path
      else
        # Subscription registrations goes through here as well.
        # Invites will come here too if there is more than 1.
        path_for_signed_in_user
      end
    end

    def successful_update_hooks
      finish_onboarding(current_user) unless onboarding_status.continue_full_onboarding?

      return unless onboarding_status.eligible_for_iterable_trigger?

      ::Onboarding::CreateIterableTriggerWorker.perform_async(iterable_params) # rubocop:disable CodeReuse/Worker
    end

    def signup_onboarding_path
      if onboarding_status.joining_a_project?
        finish_onboarding(current_user)
        path_for_signed_in_user
      elsif onboarding_status.redirect_to_company_form?
        path = new_users_sign_up_company_path(passed_through_params)
        save_onboarding_step_url(path, current_user)
        path
      else
        path = new_users_sign_up_group_path
        save_onboarding_step_url(path, current_user)
        path
      end
    end

    def track_event(action)
      ::Gitlab::Tracking.event(
        helpers.body_data_page,
        action,
        user: current_user,
        label: onboarding_status.tracking_label
      )
    end

    def onboarding_status
      Onboarding::Status.new(params.to_unsafe_h.deep_symbolize_keys, session, current_user)
    end
    strong_memoize_attr :onboarding_status
  end
end
