# frozen_string_literal: true

module Onboarding
  module SetRedirect
    extend ActiveSupport::Concern

    private

    def save_onboarding_step_url(onboarding_step_url)
      onboarding_in_progress? &&
        current_user.user_detail.update(onboarding_step_url: onboarding_step_url)
    end

    def finish_onboarding
      return unless onboarding_in_progress?

      save_onboarding_step_url(nil)
      current_user.update(onboarding_in_progress: false)
    end

    def onboarding_in_progress?
      current_user.onboarding_in_progress? && ::Feature.enabled?(:ensure_onboarding)
    end
  end
end
