# frozen_string_literal: true

module WelcomeHelper
  include ::Gitlab::Utils::StrongMemoize

  def in_trial_onboarding_flow?
    # This only comes from the submission of the company form.
    # It is then passed around to creating group/project
    # and then back to welcome controller for the
    # continuous getting started action.
    params[:trial_onboarding_flow] == 'true'
  end

  def setup_for_company_label_text
    if onboarding_status.subscription?
      _('Who will be using this GitLab subscription?')
    elsif onboarding_status.trial?
      _('Who will be using this GitLab trial?')
    else
      _('Who will be using GitLab?')
    end
  end

  def welcome_submit_button_text
    continue = _('Continue')
    get_started = _('Get started!')

    return continue if onboarding_status.subscription?
    return get_started if onboarding_status.invite? || onboarding_status.oauth?

    onboarding_status.enabled? ? continue : get_started
  end
end
