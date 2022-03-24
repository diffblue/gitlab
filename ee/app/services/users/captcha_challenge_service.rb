# frozen_string_literal: true
module Users
  class CaptchaChallengeService
    attr_reader :user, :request_ip

    def initialize(user, request_ip)
      @user = user
      @request_ip = request_ip
    end

    def execute
      return { result: false } unless Feature.enabled?(:arkose_labs_login_challenge, default_enabled: :yaml)

      if never_logged_before? || too_many_login_failures || not_logged_in_past_months || last_login_from_different_ip
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

    def last_login_from_different_ip
      user.last_sign_in_ip != request_ip
    end
  end
end
