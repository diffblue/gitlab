# frozen_string_literal: true

module Users
  class IdentityVerificationController < ApplicationController
    include AcceptsPendingInvitations
    include ActionView::Helpers::DateHelper
    include Arkose::ContentSecurityPolicy
    include IdentityVerificationHelper

    EVENT_CATEGORIES = %i[email phone credit_card error].freeze

    skip_before_action :authenticate_user!
    before_action :require_verification_user!
    before_action :require_unverified_user!, except: :success
    before_action :redirect_banned_user, only: [:show]
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
        log_event(:email, :failed_attempt, result[:reason])

        render json: result
      end
    end

    def resend_email_code
      if send_rate_limited?
        render json: { status: :failure, message: rate_limited_error_message(:email_verification_code_send) }
      else
        reset_confirmation_token

        render json: { status: :success }
      end
    end

    def send_phone_verification_code
      result = ::PhoneVerification::Users::SendVerificationCodeService.new(@user, phone_verification_params).execute

      unless result.success?
        log_event(:phone, :failed_attempt, result.reason)
        return render status: :bad_request, json: { message: result.message, reason: result.reason }
      end

      log_event(:phone, :sent_phone_verification_code)
      render json: { status: :success }
    end

    def verify_phone_verification_code
      result = ::PhoneVerification::Users::VerifyCodeService.new(@user, verify_phone_verification_code_params).execute

      unless result.success?
        log_event(:phone, :failed_attempt, result.reason)
        return render status: :bad_request, json: { message: result.message, reason: result.reason }
      end

      log_event(:phone, :success)
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
      set_redirect_url
      experiment(:phone_verification_for_low_risk_users, user: @user).track(:registration_completed)

      render 'devise/sessions/successful_verification'
    end

    def verify_credit_card
      return render_404 unless json_request? && @user.credit_card_validation.present?

      if @user.credit_card_validation.used_by_banned_user?
        @user.ban
        log_event(:credit_card, :failed_attempt, :related_to_banned_user)
        render status: :bad_request, json: { message: user_banned_error_message, reason: :related_to_banned_user }
      elsif check_for_reuse_rate_limited?
        log_event(:credit_card, :failed_attempt, :rate_limited)
        render status: :bad_request, json: {
          message: rate_limited_error_message(:credit_card_verification_check_for_reuse)
        }
      else
        log_event(:credit_card, :success)
        render json: {}
      end
    end

    private

    def set_redirect_url
      onboarding_status = ::Onboarding::Status.new(params.to_unsafe_h.deep_symbolize_keys, session, @user)
      @redirect_url = if onboarding_status.subscription?
                        # Since we need this value to stay in the stored_location_for(user) in order for
                        # us to be properly redirected for subscription signups.
                        onboarding_status.stored_user_location
                      else
                        after_sign_in_path_for(@user)
                      end
    end

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

    def redirect_banned_user
      return unless @user.banned?

      session.delete(:verification_user_id)
      redirect_to new_user_session_path, alert: user_banned_error_message
    end

    def require_arkose_verification!
      return unless Feature.enabled?(:arkose_labs_oauth_signup_challenge)
      return unless ::Arkose::Settings.enabled?(user: @user, user_agent: request.user_agent)
      return unless @user.identities.any?
      return unless @user.arkose_risk_band.blank?

      redirect_to action: :arkose_labs_challenge
    end

    def log_event(category, event, reason = nil)
      return unless category.in?(EVENT_CATEGORIES)

      category = "IdentityVerification::#{category.to_s.classify}"
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

      log_event(:error, :verification_user_not_found, reason.join(', '))
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
      log_event(:email, :success)
    end

    def reset_confirmation_token
      service = ::Users::EmailVerification::GenerateTokenService.new(attr: :confirmation_token, user: @user)
      token, encrypted_token = service.execute
      @user.update!(confirmation_token: encrypted_token, confirmation_sent_at: Time.current)
      Notify.confirmation_instructions_email(@user.email, token: token).deliver_later
      log_event(:email, :sent_instructions)
    end

    def send_rate_limited?
      ::Gitlab::ApplicationRateLimiter.throttled?(:email_verification_code_send, scope: @user)
    end

    def check_for_reuse_rate_limited?
      check_rate_limit!(:credit_card_verification_check_for_reuse, scope: request.ip) { true }
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
