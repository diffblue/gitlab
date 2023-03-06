# frozen_string_literal: true

class SmartcardController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  before_action :check_feature_availability
  before_action :check_certificate_required_host_and_port, only: :extract_certificate
  before_action :check_ngingx_certificate_header, only: :extract_certificate
  before_action :check_certificate_param, only: :verify_certificate

  feature_category :system_access

  def auth
    redirect_to extract_certificate_smartcard_url(extract_certificate_url_options)
  end

  def extract_certificate
    redirect_to verify_certificate_smartcard_url(verify_certificate_url_options)
  end

  def verify_certificate
    sign_in_with(client_certificate)
  end

  private

  def extract_certificate_url_options
    {
      host: ::Gitlab.config.smartcard.client_certificate_required_host,
      port: ::Gitlab.config.smartcard.client_certificate_required_port,
      provider: params[:provider]
    }.compact
  end

  def verify_certificate_url_options
    {
      host: ::Gitlab.config.gitlab.host,
      port: ::Gitlab.config.gitlab.port,
      provider: params[:provider],
      client_certificate: request.headers['HTTP_X_SSL_CLIENT_CERTIFICATE']
    }.compact
  end

  def client_certificate
    if ldap_provider?
      Gitlab::Auth::Smartcard::LdapCertificate.new(params[:provider], certificate_param)
    else
      Gitlab::Auth::Smartcard::Certificate.new(certificate_param)
    end
  end

  def ldap_provider?
    params[:provider].present?
  end

  def sign_in_with(certificate)
    user = certificate.find_or_create_user
    unless user&.persisted?
      flash[:alert] = _('Failed to signing using smartcard authentication')
      redirect_to new_user_session_path

      return
    end

    store_active_session
    log_audit_event(user, with: certificate.auth_method, ip_address: request.remote_ip)
    sign_in_and_redirect(user)
  end

  def nginx_certificate_header
    request.headers['HTTP_X_SSL_CLIENT_CERTIFICATE']
  end

  def certificate_param
    param = params[:client_certificate]
    return unless param

    unescaped_param = CGI.unescape(param)
    if unescaped_param.include?("\n")
      # NGINX forwarding the $ssl_client_escaped_cert variable
      unescaped_param
    else
      # older version of NGINX forwarding the now deprecated $ssl_client_cert variable
      param.gsub(/ (?!CERTIFICATE)/, "\n")
    end
  end

  def check_feature_availability
    render_404 unless ::Gitlab::Auth::Smartcard.enabled?
  end

  def check_certificate_required_host_and_port
    unless request.host == ::Gitlab.config.smartcard.client_certificate_required_host &&
      request.port == ::Gitlab.config.smartcard.client_certificate_required_port
      render_404
    end
  end

  def check_ngingx_certificate_header
    unless nginx_certificate_header.present?
      access_denied!(_('Smartcard authentication failed: client certificate header is missing.'), 401)
    end
  end

  def check_certificate_param
    unless certificate_param.present?
      access_denied!(_('Smartcard authentication failed: client certificate header is missing.'), 401)
    end
  end

  def store_active_session
    Gitlab::Auth::Smartcard::SessionEnforcer.new.update_session
  end

  def log_audit_event(user, options = {})
    AuditEventService.new(user, user, options).for_authentication.security_event
  end

  def after_sign_in_path_for(resource)
    stored_location_for(:redirect) || stored_location_for(resource) || root_url(port: Gitlab.config.gitlab.port)
  end
end
