# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SessionsController, :geo do
  include DeviseHelpers
  include EE::GeoHelpers

  before do
    set_devise_mapping(context: @request)
  end

  describe '#new' do
    context 'on a Geo secondary node' do
      let_it_be(:primary_node) { create(:geo_node, :primary) }
      let_it_be(:secondary_node) { create(:geo_node) }

      before do
        stub_current_geo_node(secondary_node)
      end

      shared_examples 'a valid oauth authentication redirect' do
        it 'redirects to the correct oauth_geo_auth_url' do
          get(:new)

          redirect_uri = URI.parse(response.location)
          redirect_params = CGI.parse(redirect_uri.query)

          expect(response).to have_gitlab_http_status(:found)
          expect(response).to redirect_to %r(\A#{Gitlab.config.gitlab.url}/oauth/geo/auth)
          expect(redirect_params['state'].first).to end_with(':')
        end
      end

      context 'when relative URL is configured' do
        before do
          host = 'http://this.is.my.host/secondary-relative-url-part'

          stub_config_setting(url: host, https: false)
          stub_default_url_options(host: "this.is.my.host", script_name: '/secondary-relative-url-part')
          request.headers['HOST'] = host
        end

        it_behaves_like 'a valid oauth authentication redirect'
      end

      context 'with a tampered HOST header' do
        before do
          request.headers['HOST'] = 'http://this.is.not.my.host'
        end

        it_behaves_like 'a valid oauth authentication redirect'
      end

      context 'with a tampered X-Forwarded-Host header' do
        before do
          request.headers['X-Forwarded-Host'] = 'http://this.is.not.my.host'
        end

        it_behaves_like 'a valid oauth authentication redirect'
      end

      context 'without a tampered header' do
        it_behaves_like 'a valid oauth authentication redirect'
      end
    end
  end

  describe '#create' do
    before do
      allow(::Gitlab).to receive(:com?).and_return(true)
    end

    context 'with wrong credentials' do
      context 'when is a trial form' do
        it 'redirects to new trial sign in page' do
          post :create, params: { trial: true, user: { login: 'foo@bar.com', password: '11111' } }

          expect(response).to render_template("trial_registrations/new")
        end
      end

      context 'when is a regular form' do
        it 'redirects to the regular sign in page' do
          post :create, params: { user: { login: 'foo@bar.com', password: '11111' } }

          expect(response).to render_template("devise/sessions/new")
        end
      end
    end

    context 'when using two-factor authentication' do
      def authenticate_2fa(otp_user_id: user.id, **user_params)
        post(:create, params: { user: user_params }, session: { otp_user_id: otp_user_id })
      end

      context 'when OTP authentication fails' do
        it_behaves_like 'an auditable failed authentication' do
          let_it_be(:user) { create(:user, :two_factor) }
          let(:operation) { authenticate_2fa(otp_attempt: 'invalid', otp_user_id: user.id) }
          let(:method) { 'OTP' }
        end
      end

      context 'when U2F authentication fails' do
        before do
          allow(U2fRegistration).to receive(:authenticate).and_return(false)
        end

        it_behaves_like 'an auditable failed authentication' do
          let_it_be(:user) { create(:user, :two_factor_via_u2f) }
          let(:operation) { authenticate_2fa(device_response: 'invalid', otp_user_id: user.id) }
          let(:method) { 'U2F' }
        end
      end

      context 'when WebAuthn authentication fails' do
        before do
          stub_feature_flags(webauthn: true)
          webauthn_authenticate_service = instance_spy(Webauthn::AuthenticateService, execute: false)
          allow(Webauthn::AuthenticateService).to receive(:new).and_return(webauthn_authenticate_service)
        end

        it_behaves_like 'an auditable failed authentication' do
          let_it_be(:user) { create(:user, :two_factor_via_webauthn) }
          let(:operation) { authenticate_2fa(device_response: 'invalid', otp_user_id: user.id) }
          let(:method) { 'WebAuthn' }
        end
      end
    end

    context 'when user is not allowed to log in using password' do
      let_it_be(:user) { create(:user, provisioned_by_group: build(:group)) }

      it 'does not authenticate the user' do
        post(:create, params: { user: { login: user.username, password: user.password } })

        expect(@request.env['warden']).not_to be_authenticated
        expect(flash[:alert]).to include('You are not allowed to log in using password')
      end
    end
  end
end
