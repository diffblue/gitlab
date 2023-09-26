# frozen_string_literal: true

class Oauth::GeoAuthController < BaseActionController
  rescue_from Gitlab::Geo::OauthApplicationUndefinedError, with: :undefined_oauth_application
  rescue_from OAuth2::Error, with: :auth

  def auth
    unless login_state.valid?
      redirect_to root_url
      return
    end

    redirect_to oauth.authorize_url(redirect_uri: oauth_geo_callback_url, state: params[:state])
  end

  def callback
    unless login_state.valid?
      redirect_to new_user_session_path
      return
    end

    token = oauth.get_token(params[:code], redirect_uri: oauth_geo_callback_url)
    user  = user_from_oauth_token(token)

    if user && bypass_sign_in(user)
      after_sign_in_with_gitlab(token)
    else
      invalid_credentials
    end
  end

  def logout
    token = Gitlab::Geo::Oauth::LogoutToken.new(current_user, params[:state])

    if token.valid?
      sign_out current_user
      after_sign_out_with_gitlab(token)
    else
      invalid_access_token(token)
    end
  end

  private

  def oauth
    @oauth ||= Gitlab::Geo::Oauth::Session.new
  end

  def user_from_oauth_token(token)
    remote_user = oauth.authenticate(token)
    UserFinder.new(remote_user['id']).find_by_id if remote_user
  end

  def login_state
    Gitlab::Geo::Oauth::LoginState.from_state(params[:state])
  end

  def after_sign_in_with_gitlab(token)
    session[:access_token] = token

    # Prevent alert from popping up on the first page shown after authentication.
    flash[:alert] = nil

    redirect_to(login_state.return_to || root_path)
  end

  def after_sign_out_with_gitlab(token)
    session[:user_return_to] = token.return_to
    redirect_to(root_path)
  end

  def invalid_credentials
    @error = 'Cannot find user to login. Your account may have been deleted.'
    render :error, layout: 'errors'
  end

  def undefined_oauth_application
    @error = 'There are no OAuth application defined for this Geo node. Please ask your administrator to visit "Geo Nodes" on admin screen and click on "Repair authentication".'
    render :error, layout: 'errors'
  end

  def invalid_access_token(token)
    message = token.errors.full_messages.join(', ')
    @error = "There is a problem with the OAuth access_token: #{message}"
    render :error, layout: 'errors'
  end
end
