# frozen_string_literal: true

module EE
  module OmniauthCallbacksController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include ::Onboarding::SetRedirect
    end

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
      unauth_author = ::Gitlab::Audit::UnauthenticatedAuthor.new(name: author)
      user = ::User.new(id: unauth_author.id, name: author)
      ::Gitlab::Audit::Auditor.audit({
        name: "omniauth_login_failed",
        author: unauth_author,
        scope: user,
        target: user,
        additional_details: {
          failed_login: provider.upcase,
          author_name: user.name,
          target_details: user.name
        },
        message: "#{provider.upcase} login failed"
      })
    end

    override :after_sign_up_path
    def after_sign_up_path
      # The sign in path for creating an account with sso will not have params as there are no
      # leads that would start out there. So we need to protect for that here by using fetch
      onboarding_params = request.env.fetch('omniauth.params', {}).slice('glm_source', 'glm_content', 'trial')

      ::Gitlab::Utils.add_url_parameters(super, onboarding_params)
    end

    override :perform_registration_tasks
    def perform_registration_tasks(user, provider)
      # We need to do this here since the subscription flow relies on what was set in the stored_location_for(:user)
      # that was set on initial redirect from the SubscriptionsController#new and super will wipe that out.
      # Then the IdentityVerificationController#success will get whatever is set in super instead of the subscription
      # path we desire.
      super unless ::Onboarding::Status.new(params.to_unsafe_h.deep_symbolize_keys, session, user).subscription?

      # This also protects the sub classes group saml and ldap from staring onboarding
      # as we don't want those to onboard.
      return unless provider.to_sym.in?(::AuthHelper.providers_for_base_controller)

      start_onboarding!(after_sign_up_path, user)
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
