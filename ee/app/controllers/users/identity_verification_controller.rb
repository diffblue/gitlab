# frozen_string_literal: true

module Users
  class IdentityVerificationController < ApplicationController
    include AcceptsPendingInvitations
    include ActionView::Helpers::DateHelper
    include ZuoraCSP

    skip_before_action :authenticate_user!
    before_action :require_unconfirmed_user!

    feature_category :authentication_and_authorization

    layout 'minimal'

    def show
    end

    def verify_email_code
      result = verify_token

      if result[:status] == :success
        confirm_user

        render json: {
          status: :success,
          redirect_url: users_successful_verification_path
        }
      else
        log_identity_verification(:failed_attempt, result[:reason])

        render json: result
      end
    end

    def resend_email_code
      if send_rate_limited?
        render json: { status: :failure, message: send_rate_limited_error_message }
      else
        reset_confirmation_token

        render json: { status: :success }
      end
    end

    private

    def require_unconfirmed_user!
      @user = User.find_by_id(session[:verification_user_id])
      access_denied! if !@user || @user.identity_verified?
    end

    def log_identity_verification(event, reason = nil)
      Gitlab::AppLogger.info(
        message: 'Identity Verification',
        event: event.to_s.titlecase,
        username: @user.username,
        ip: request.ip,
        reason: reason.to_s
      )
      ::Gitlab::Tracking.event('IdentityVerification::Email', event.to_s, property: reason.to_s, user: @user)
    end

    def verify_token
      ::Users::EmailVerification::ValidateTokenService.new(
        attr: :confirmation_token,
        user: @user,
        token: params.require(:identity_verification).permit(:code)[:code]
      ).execute
    end

    def confirm_user
      @user.confirm
      accept_pending_invitations(user: @user)
      sign_in(@user)
      log_identity_verification(:success)
    end

    def reset_confirmation_token
      token, encrypted_token = ::Users::EmailVerification::GenerateTokenService.new(attr: :confirmation_token).execute
      @user.update!(confirmation_token: encrypted_token, confirmation_sent_at: Time.current)
      Notify.confirmation_instructions_email(@user.email, token: token).deliver_later
      log_identity_verification(:sent_instructions)
    end

    def send_rate_limited?
      ::Gitlab::ApplicationRateLimiter.throttled?(:email_verification_code_send, scope: @user)
    end

    def send_rate_limited_error_message
      interval_in_seconds = ::Gitlab::ApplicationRateLimiter.rate_limits[:email_verification_code_send][:interval]
      email_verification_code_send_interval = distance_of_time_in_words(interval_in_seconds)
      format(s_("IdentityVerification|You've reached the maximum amount of resends. "\
        'Wait %{interval} and try again.'), interval: email_verification_code_send_interval)
    end
  end
end
