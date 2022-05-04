# frozen_string_literal: true
module Users
  class CaptchaChallengeService
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def execute
      return { result: false } unless Feature.enabled?(:arkose_labs_login_challenge)

      if !user || never_logged_before? || too_many_login_failures || not_logged_in_past_months
        return { result: true }
      end

      { result: false }
    end

    private

    def never_logged_before?
      user.last_sign_in_at.nil?
    end

    def too_many_login_failures
      user.failed_attempts >= 3
    end

    def not_logged_in_past_months
      user.last_sign_in_at <= Date.today - 3.months
    end
  end
end
