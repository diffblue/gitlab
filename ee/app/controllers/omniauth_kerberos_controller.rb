# frozen_string_literal: true

class OmniauthKerberosController < ApplicationController
  include KerberosHelper

  skip_before_action :authenticate_user!

  feature_category :system_access

  def negotiate
    if spnego_provided? && (krb_principal = spnego_credentials!(spnego_token))
      session[OmniAuth::Strategies::Kerberos::SESSION_KEY] = krb_principal
      send_final_spnego_response
      redirect_to user_kerberos_omniauth_callback_path
      return
    end

    # When the browser is Kerberos-aware, this response will make it try to
    # get a Kerberos ticket and present it to us via an SPNEGO token.
    #
    # When the browser does not know Kerberos, or if it tried to
    # authenticate with Kerberos but failed, it shows the special 'Kerberos
    # denied' 401 page to the user.
    #
    # We cannot redirect the user to the sign-in page because we do not know
    # when the browser has given up.
    #
    headers['Www-Authenticate'] = spnego_challenge
    render template: 'errors/kerberos_denied',
      formats: :html,
      locals: { layout: 'errors' },
      status: :unauthorized
  end
end
