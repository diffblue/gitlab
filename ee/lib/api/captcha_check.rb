# frozen_string_literal: true

module API
  class CaptchaCheck < ::API::Base
    feature_category :instance_resiliency

    params do
      requires :username, type: String, desc: 'The username of a user'
    end

    content_type :json, 'application/json'
    default_format :json

    resource :users do
      desc 'Post captcha check result for ArkoseLabs' do
        detail 'Returns captcha check result'
        success code: 200, model: Entities::CaptchaCheck
        failure [
          { code: 404, message: 'Not Found' }
        ]
      end
      post '/captcha_check' do
        not_found! 'User' unless Feature.enabled?(:arkose_labs_login_challenge)

        rate_limit_reached = false
        check_rate_limit!(:search_rate_limit_unauthenticated, scope: [ip_address]) do
          rate_limit_reached = true
        end

        status 200

        if rate_limit_reached || !valid_username?(params[:username])
          present({ result: true }, with: Entities::CaptchaCheck)
        else
          user = ::User.find_by_login(params[:username])
          present(::Users::CaptchaChallengeService.new(user).execute, with: Entities::CaptchaCheck)
        end
      end
    end

    helpers do
      def valid_username?(username)
        username.present? && valid_length?(username)
      end

      def valid_length?(username)
        username.length >= User::MIN_USERNAME_LENGTH && username.length <= User::MAX_USERNAME_LENGTH
      end
    end
  end
end
