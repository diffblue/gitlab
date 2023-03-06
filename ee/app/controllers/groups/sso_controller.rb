# frozen_string_literal: true

class Groups::SsoController < Groups::ApplicationController
  include InternalRedirect
  skip_before_action :group

  before_action :authenticate_user!, only: [:unlink]
  before_action :require_group_saml_instance!
  before_action :require_licensed_group!, except: [:unlink]
  before_action :require_saml_provider!
  before_action :require_enabled_provider!, except: [:unlink]
  before_action :check_user_can_sign_in_with_provider, only: [:saml]
  before_action :group, only: [:saml]
  before_action :redirect_if_group_moved
  before_action :check_oauth_data, only: [:sign_up_form, :sign_up, :authorize_managed_account]

  layout 'devise'

  feature_category :system_access
  urgency :low

  def saml
    @redirect_path = safe_redirect_path(params[:redirect]) || group_path(unauthenticated_group)
    @group_path = unauthenticated_group.path
    @group_name = unauthenticated_group.full_name
    @group_saml_identity = linked_identity
    @auto_redirect_to_provider = current_user&.group_sso?(unauthenticated_group)

    render layout: 'devise_empty' if @auto_redirect_to_provider
  end

  def unlink
    return route_not_found unless linked_identity

    GroupSaml::Identity::DestroyService.new(linked_identity).execute

    if current_user.authorized_by_provisioning_group?(unauthenticated_group)
      sign_out current_user
    else
      redirect_to profile_account_path
    end
  end

  def sign_up_form
    @group_name = unauthenticated_group.full_name

    render_sign_up_form
  end

  def sign_up
    sign_up_service = GroupSaml::SignUpService.new(new_user, unauthenticated_group, session)

    if sign_up_service.execute
      session['oauth_data'] = nil
      sign_out
      flash[:notice] = _('Sign up was successful! Please confirm your email to sign in.')
      redirect_to_sign_in
    else
      render_sign_up_form
    end
  end

  def authorize_managed_account
    transfer_membership_service = GroupSaml::GroupManagedAccounts::TransferMembershipService.new(current_user, unauthenticated_group, session)

    if transfer_membership_service.execute
      session['oauth_data'] = nil
      flash[:notice] = nil
      store_active_saml_session

      redirect_to group_url(unauthenticated_group)
    else
      render_sign_up_form
    end
  end

  private

  def group
    @group ||= unauthenticated_group
  end

  def new_user
    @new_user ||= User.new(new_user_params)
  end
  # Devise compatible name
  alias_method :resource, :new_user
  helper_method :resource

  def new_user_params
    new_user_params = params.fetch(:new_user, {}).permit(:username, :name).merge(email: oauth_data.email, name: oauth_data.name)
    new_user_params[:username] = generate_unique_username unless new_user_params[:username]
    new_user_params
  end

  def generate_unique_username
    username = ::Namespace.clean_path(oauth_data.username)
    ::Gitlab::Utils::Uniquify.new.string(username) { |s| !NamespacePathValidator.valid_path?(s) }
  end

  def check_oauth_data
    route_not_found unless unauthenticated_group.saml_provider.enforced_group_managed_accounts? && oauth_data.present?
  end

  def oauth_data
    @oauth_data ||= if session['oauth_data'] && session['oauth_group_id'] == unauthenticated_group.id
                      Gitlab::Auth::OAuth::AuthHash.new(session['oauth_data'])
                    end
  end

  def render_sign_up_form
    flash[:notice] = _('%{group_name} uses group managed accounts. You need to create a new GitLab account which will be managed by %{group_name}.') % { group_name: unauthenticated_group.full_name }

    render :sign_up_form
  end

  def linked_identity
    @linked_identity ||= GroupSamlIdentityFinder.new(user: current_user).find_linked(group: unauthenticated_group)
  end

  def unauthenticated_group
    @unauthenticated_group ||= Group.find_by_full_path(params[:group_id], follow_redirects: true)
  end

  def store_active_saml_session
    Gitlab::Auth::GroupSaml::SsoEnforcer.new(unauthenticated_group.saml_provider).update_session
  end

  def require_group_saml_instance!
    route_not_found unless Gitlab::Auth::GroupSaml::Config.enabled?
  end

  def require_licensed_group!
    route_not_found unless unauthenticated_group&.feature_available?(:group_saml)
  end

  def require_saml_provider!
    redirect_settings_or_not_found unless unauthenticated_group.saml_provider
  end

  def require_enabled_provider!
    redirect_settings_or_not_found unless unauthenticated_group.saml_provider&.enabled?
  end

  def redirect_settings_or_not_found
    if can?(current_user, :admin_group_saml, unauthenticated_group)
      flash[:notice] = 'SAML sign on has not been configured for this group'
      redirect_to [@unauthenticated_group, :saml_providers]
    else
      route_not_found
    end
  end

  def check_user_can_sign_in_with_provider
    actor = saml_discovery_token_actor || current_user
    route_not_found unless can?(actor, :sign_in_with_saml_provider, unauthenticated_group.saml_provider)
  end

  def saml_discovery_token_actor
    Gitlab::Auth::GroupSaml::TokenActor.new(params[:token]) if params[:token]
  end

  def redirect_if_group_moved
    ensure_canonical_path(unauthenticated_group, params[:group_id])
  end

  def redirect_to_sign_in
    redirect_to sso_group_saml_providers_url(unauthenticated_group, token: unauthenticated_group.saml_discovery_token)
  end
end
