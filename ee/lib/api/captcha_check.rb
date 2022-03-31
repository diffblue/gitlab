# frozen_string_literal: true

module API
  class CaptchaCheck < ::API::Base
    feature_category :authentication_and_authorization

    params do
      requires :username, type: String, desc: 'The username of a user'
    end

    content_type :json, 'application/json'
    default_format :json

    resource :users do
      desc 'Get captcha check result for ArkoseLabs'
      get ':username/captcha_check', requirements: { username: %r{[^/]+} } do
        not_found! 'User' unless Feature.enabled?(:arkose_labs_login_challenge, default_enabled: :yaml)

        rate_limit_reached = false
        check_rate_limit!(:search_rate_limit_unauthenticated, scope: [ip_address]) do
          rate_limit_reached = true
        end

        if rate_limit_reached
          present({ result: true }, with: Entities::CaptchaCheck)
        else
          user = ::User.by_login(params[:username])
          not_found! 'User' unless user
          present(::Users::CaptchaChallengeService.new(user, ip_address).execute, with: Entities::CaptchaCheck)
        end
      end
    end
  end
end
