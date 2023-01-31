# frozen_string_literal: true

module EE
  module WelcomeHelper
    include ::Gitlab::Utils::StrongMemoize

    def in_subscription_flow?
      redirect_path == new_subscriptions_path
    end

    def in_trial_onboarding_flow?
      # This only comes from the submission of the company form.
      # It is then passed around to creating group/project
      # and then back to welcome controller for the
      # continuous getting started action.
      params[:trial_onboarding_flow] == 'true'
    end

    def in_oauth_flow?
      redirect_path&.starts_with?(oauth_authorization_path)
    end

    def setup_for_company_label_text
      if in_subscription_flow?
        _('Who will be using this GitLab subscription?')
      elsif trial_selected?
        _('Who will be using this GitLab trial?')
      else
        _('Who will be using GitLab?')
      end
    end

    def trial_selected?
      params[:trial] == 'true'
    end

    def show_signup_flow_progress_bar?
      return true if in_subscription_flow?
      return false if user_has_memberships? || in_oauth_flow? || trial_selected?

      signup_onboarding_enabled?
    end

    def welcome_submit_button_text
      continue = _('Continue')
      get_started = _('Get started!')

      return continue if in_subscription_flow?
      return get_started if user_has_memberships? || in_oauth_flow?

      signup_onboarding_enabled? ? continue : get_started
    end

    def data_attributes_for_progress_bar_js_component
      {
        is_in_subscription_flow: in_subscription_flow?.to_s,
        is_signup_onboarding_enabled: signup_onboarding_enabled?.to_s
      }
    end

    def user_has_memberships?
      strong_memoize(:user_has_memberships) do
        current_user.members.any?
      end
    end

    def signup_onboarding_enabled?
      ::Gitlab.com?
    end
  end
end
