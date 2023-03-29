# frozen_string_literal: true

module EE
  module OmniauthCallbacksController
    extend ::Gitlab::Utils::Override

    override :openid_connect
    def openid_connect
      if License.feature_available?(:oidc_client_groups_claim)
        omniauth_flow(::Gitlab::Auth::Oidc)
      else
        super
      end
    end

    private

    override :log_failed_login
    def log_failed_login(author, provider)
      ::AuditEventService.new(
        author,
        nil,
        with: provider
      ).for_failed_login.unauth_security_event
    end

    override :sign_in_and_redirect_or_verify_identity
    def sign_in_and_redirect_or_verify_identity(user, auth_user, new_user)
      return super if user.blocked? # When `block_auto_created_users` is set to true
      return super unless auth_user.identity_verification_enabled?(user)
      return super if !new_user && user.identity_verified?

      service_class = ::Users::EmailVerification::SendCustomConfirmationInstructionsService
      service_class.new(user).execute if new_user
      session[:verification_user_id] = user.id
      ::User.sticking.stick_or_unstick_request(request.env, :user, user.id)

      redirect_to identity_verification_path
    end
  end
end
