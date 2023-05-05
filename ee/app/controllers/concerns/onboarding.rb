# frozen_string_literal: true

module Onboarding
  def self.user_onboarding_in_progress?(user)
    user.present? &&
      user.onboarding_in_progress? &&
      user_onboarding_enabled?
  end

  def self.user_onboarding_enabled?
    ::Feature.enabled?(:ensure_onboarding) &&
      ::Gitlab::CurrentSettings.should_check_namespace_plan?
  end
end
