# frozen_string_literal: true

module EE
  module RegistrationsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Gitlab::Utils::StrongMemoize

    prepended do
      include ArkoseLabsCSP

      skip_before_action :check_captcha, if: -> { ::Feature.enabled?(:arkose_labs_signup_challenge) }
      before_action only: [:new, :create] do
        push_frontend_feature_flag(:arkose_labs_signup_challenge)
      end
      before_action :ensure_can_remove_self, only: [:destroy]
    end

    override :create
    def create
      ensure_correct_params!

      unless verify_arkose_labs_token
        flash[:alert] = _('Complete verification to sign up.')
        render action: 'new'
        return
      end

      super
    end

    private

    override :after_request_hook
    def after_request_hook(user)
      super

      log_audit_event(user)
      record_arkose_data(user)
    end

    override :set_blocked_pending_approval?
    def set_blocked_pending_approval?
      super || ::Gitlab::CurrentSettings.should_apply_user_signup_cap?
    end

    def ensure_can_remove_self
      unless current_user&.can_remove_self?
        redirect_to profile_account_path,
                    status: :see_other,
                    alert: s_('Profiles|Account could not be deleted. GitLab was unable to verify your identity.')
      end
    end

    def log_audit_event(user)
      return unless user&.persisted?

      ::AuditEventService.new(
        user,
        user,
        action: :custom,
        custom_message: _('Instance access request')
      ).for_user.security_event
    end

    def verify_arkose_labs_token
      return true unless ::Feature.enabled?(:arkose_labs_signup_challenge)
      return false unless params[:arkose_labs_token].present?

      arkose_labs_verify_response.present?
    end

    def arkose_labs_verify_response
      result = Arkose::TokenVerificationService.new(session_token: params[:arkose_labs_token]).execute
      result.success? ? result.payload[:response] : nil
    end
    strong_memoize_attr :arkose_labs_verify_response

    def record_arkose_data(user)
      return unless ::Feature.enabled?(:arkose_labs_signup_challenge)
      return unless arkose_labs_verify_response

      Arkose::RecordUserDataService.new(
        response: arkose_labs_verify_response,
        user: user
      ).execute
    end
  end
end
