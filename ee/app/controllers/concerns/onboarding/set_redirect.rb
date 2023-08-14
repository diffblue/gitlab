# frozen_string_literal: true

module Onboarding
  module SetRedirect
    extend ActiveSupport::Concern

    private

    def save_onboarding_step_url(onboarding_step_url, user)
      Onboarding.user_onboarding_in_progress?(user) &&
        user.user_detail.update(onboarding_step_url: onboarding_step_url)
    end

    def start_onboarding(onboarding_step_url, user)
      return unless ::Gitlab::CurrentSettings.should_check_namespace_plan?

      user.onboarding_in_progress = true
      user.user_detail.onboarding_step_url = onboarding_step_url
      user
    end

    def start_onboarding!(...)
      start_onboarding(...)&.save
    end

    def finish_onboarding(user)
      return unless Onboarding.user_onboarding_in_progress?(user)

      user.update(onboarding_step_url: nil, onboarding_in_progress: false)
    end
  end
end
