# frozen_string_literal: true

module Users
  class IdentityVerificationController < ApplicationController
    include AcceptsPendingInvitations
    include ActionView::Helpers::DateHelper
    include Arkose::ContentSecurityPolicy

    skip_before_action :authenticate_user!
    before_action :require_verification_user!
    before_action :require_unverified_user!, except: :success
    before_action :require_arkose_verification!, except: [:arkose_labs_challenge, :verify_arkose_labs_session]

    feature_category :system_access

    layout 'minimal'

    def show; end

    def verify_email_code
      result = verify_token

      if result[:status] == :success
        confirm_user

        render json: { status: :success }
      else
        log_identity_verification('Email', :failed_attempt, result[:reason])

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

    def send_phone_verification_code
      result = ::PhoneVerification::Users::SendVerificationCodeService.new(@user, phone_verification_params).execute

      unless result.success?
        log_identity_verification('Phone', :failed_attempt, result.reason)
        return render status: :bad_request, json: { message: result.message }
      end

      log_identity_verification('Phone', :sent_phone_verification_code)
      render json: { status: :success }
    end

    def verify_phone_verification_code
      result = ::PhoneVerification::Users::VerifyCodeService.new(@user, verify_phone_verification_code_params).execute

      unless result.success?
        log_identity_verification('Phone', :failed_attempt, result.reason)
        return render status: :bad_request, json: { message: result.message }
      end

      log_identity_verification('Phone', :success)
      render json: { status: :success }
    end

    def arkose_labs_challenge; end

    def verify_arkose_labs_session
      unless verify_arkose_labs_token
        flash[:alert] = _('IdentityVerification|Complete verification to sign in.')
        return render action: :arkose_labs_challenge
      end

      redirect_to action: :show
    end

    def success
      return redirect_to identity_verification_path unless @user.identity_verified?

      sign_in(@user)
      session.delete(:verification_user_id)
      @redirect_url = after_sign_in_path_for(@user)

      render 'devise/sessions/successful_verification'
    end

    private

    def require_verification_user!
      if verification_user_id = session[:verification_user_id]
        User.sticking.stick_or_unstick_request(request.env, :user, verification_user_id)
        @user = User.find_by_id(verification_user_id)
        return if @user.present?
      end

      log_verification_user_not_found
      redirect_to root_path
    end

    def require_unverified_user!
      redirect_to success_identity_verification_path if @user.identity_verified?
    end

    def require_arkose_verification!
      return unless Feature.enabled?(:arkose_labs_oauth_signup_challenge)
      return if ::Gitlab::Qa.request?(request.user_agent)
      return unless @user.identities.any?
      return unless @user.arkose_risk_band.blank?

      redirect_to action: :arkose_labs_challenge
    end

    def log_identity_verification(method, event, reason = nil)
      return unless %w[Email Phone Error].include?(method)

      category = "IdentityVerification::#{method}"
      user = @user || current_user

      Gitlab::AppLogger.info(
        message: category,
        event: event.to_s.titlecase,
        action: action_name,
        username: user&.username,
        ip: request.ip,
        reason: reason.to_s,
        referer: request.referer
      )
      ::Gitlab::Tracking.event(category, event.to_s, property: reason.to_s, user: user)
    end

    def log_verification_user_not_found
      reason = ["signed_in: #{user_signed_in?}"]
      reason << "verification_user_id: #{session[:verification_user_id]}" if session[:verification_user_id].present?

      if user_signed_in?
        reason << "state: #{current_user.identity_verification_state}"
        reason << "verified: #{current_user.identity_verified?}"
      end

      log_identity_verification('Error', :verification_user_not_found, reason.join(', '))
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
      log_identity_verification('Email', :success)
    end

    def reset_confirmation_token
      service = ::Users::EmailVerification::GenerateTokenService.new(attr: :confirmation_token, user: @user)
      token, encrypted_token = service.execute
      @user.update!(confirmation_token: encrypted_token, confirmation_sent_at: Time.current)
      Notify.confirmation_instructions_email(@user.email, token: token).deliver_later
      log_identity_verification('Email', :sent_instructions)
    end

    def send_rate_limited?
      ::Gitlab::ApplicationRateLimiter.throttled?(:email_verification_code_send, scope: @user)
    end

    def send_rate_limited_error_message
      interval_in_seconds = ::Gitlab::ApplicationRateLimiter.rate_limits[:email_verification_code_send][:interval]
      email_verification_code_send_interval = distance_of_time_in_words(interval_in_seconds)
      format(s_("IdentityVerification|You've reached the maximum amount of resends. " \
                'Wait %{interval} and try again.'), interval: email_verification_code_send_interval)
    end

    def phone_verification_params
      params.require(:identity_verification).permit(:country, :international_dial_code, :phone_number)
    end

    def verify_phone_verification_code_params
      params.require(:identity_verification).permit(:verification_code)
    end

    def verify_arkose_labs_token
      return false unless params[:arkose_labs_token].present?

      result = Arkose::TokenVerificationService.new(session_token: params[:arkose_labs_token], user: @user).execute
      result.success?
    end
  end
end
