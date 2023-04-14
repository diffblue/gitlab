# frozen_string_literal: true

module EE
  module SessionsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      include Arkose::ContentSecurityPolicy

      before_action :gitlab_geo_logout, only: [:destroy]
      before_action only: [:new] do
        push_frontend_feature_flag(:arkose_labs_login_challenge)
      end
      prepend_before_action :complete_identity_verification, only: :create
    end

    override :new
    def new
      return super if signed_in?

      if ::Gitlab::Geo.secondary_with_primary?
        current_node_uri = URI(GeoNode.current_node_url)
        state = geo_login_state.encode
        redirect_to oauth_geo_auth_url(host: current_node_uri.host, port: current_node_uri.port, state: state)
      else
        if ::Feature.enabled?(:arkose_labs_login_challenge)
          @arkose_labs_public_key ||= ::Arkose::Settings.arkose_public_api_key # rubocop:disable Gitlab/ModuleWithInstanceVariables
          @arkose_labs_domain ||= ::Arkose::Settings.arkose_labs_domain # rubocop:disable Gitlab/ModuleWithInstanceVariables
        end

        super
      end
    end

    protected

    override :auth_options
    def auth_options
      if params[:trial]
        { scope: resource_name, recall: "trial_registrations#new" }
      else
        super
      end
    end

    private

    def gitlab_geo_logout
      return unless ::Gitlab::Geo.secondary?

      # The @geo_logout_state instance variable is used within
      # ApplicationController#after_sign_out_path_for to redirect
      # the user to the logout URL on the primary after sign out
      # on the secondary.
      @geo_logout_state = geo_logout_state.encode # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    def geo_login_state
      ::Gitlab::Geo::Oauth::LoginState.new(return_to: sanitize_redirect(geo_return_to_after_login))
    end

    def geo_logout_state
      ::Gitlab::Geo::Oauth::LogoutState.new(token: session[:access_token], return_to: geo_return_to_after_logout)
    end

    def geo_return_to_after_login
      stored_redirect_uri || ::Gitlab::Utils.append_path(root_url, session[:user_return_to].to_s)
    end

    def geo_return_to_after_logout
      safe_redirect_path_for_url(request.referer)
    end

    override :log_failed_login
    def log_failed_login
      login = request.filtered_parameters.dig('user', 'login')
      audit_event_service = ::AuditEventService.new(login, nil)
      audit_event_service.for_failed_login.unauth_security_event

      super
    end

    override :check_captcha
    def check_captcha
      if ::Feature.enabled?(:arkose_labs_login_challenge)
        check_arkose_captcha
      else
        super
      end
    end

    def check_arkose_captcha
      return unless user_params[:password].present?

      user = ::User.find_by_login(user_params[:login])
      return unless user.present?

      if params[:arkose_labs_token].present?
        verify_arkose_token(user)
      else
        verify_token_required(user)
      end
    end

    def verify_arkose_token(user)
      return if ::Gitlab::Qa.request?(request.user_agent)

      result = Arkose::TokenVerificationService.new(session_token: params[:arkose_labs_token], user: user).execute

      if result.success? && result.payload[:low_risk]
        increment_successful_login_captcha_counter
      else
        failed_login_captcha
      end
    end

    def verify_token_required(user)
      should_challenge = ::Users::CaptchaChallengeService.new(user).execute
      return unless should_challenge[:result]

      failed_login_captcha
    end

    def failed_login_captcha
      increment_failed_login_captcha_counter

      self.resource = resource_class.new
      flash[:alert] = 'Login failed. Please retry from your primary device and network.'
      flash.delete :recaptcha_error

      add_gon_variables

      respond_with_navigational(resource) { render :new }
    end

    def complete_identity_verification
      user = ::User.find_by_login(user_params[:login])

      return if !user || !user.valid_password?(user_params[:password]) || user.access_locked?
      return if ::Gitlab::Qa.request?(request.user_agent)
      return if !user.identity_verification_enabled? || user.identity_verified?

      # When identity verification is enabled, store the user id in the session and redirect to the
      # identity verification page instead of displaying a Devise flash alert on the sign in page.
      session[:verification_user_id] = user.id
      redirect_to identity_verification_path
    end
  end
end
