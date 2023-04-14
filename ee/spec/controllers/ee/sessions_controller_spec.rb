# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SessionsController, :geo, feature_category: :system_access do
  include DeviseHelpers
  include EE::GeoHelpers

  let(:arkose_labs_public_api_key) { 'foo' }

  before do
    set_devise_mapping(context: @request)
    stub_application_setting(arkose_labs_public_api_key: arkose_labs_public_api_key)
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

    context 'with Arkose reCAPTCHA' do
      before do
        stub_feature_flags(arkose_labs_login_challenge: true)
      end

      let(:user) { create(:user) }
      let(:session_token) { '22612c147bb418c8.2570749403' }
      let(:user_params) { { login: user.username, password: user.password } }
      let(:params) { { arkose_labs_token: session_token, user: user_params } }

      context 'when ArkoseLabs namespace setting is not set' do
        it 'passes the default API domain to the view' do
          get(:new)

          expect(subject.instance_variable_get(:@arkose_labs_domain)).to eq "client-api.arkoselabs.com"
        end
      end

      context 'when ArkoseLabs namespace setting is set' do
        before do
          stub_application_setting(arkose_labs_namespace: "gitlab")
        end

        it 'passes the custom API domain to the view' do
          get(:new)

          expect(subject.instance_variable_get(:@arkose_labs_domain)).to eq "gitlab-api.arkoselabs.com"
        end
      end

      context 'when the user was verified by Arkose' do
        let(:low_risk) { true }

        before do
          allow_next_instance_of(Arkose::TokenVerificationService) do |instance|
            response = ServiceResponse.success(payload: { low_risk: low_risk })
            allow(instance).to receive(:execute).and_return(response)
          end
        end

        context 'when user is low risk' do
          it 'successfully logs in the user' do
            post(:create, params: params, session: {})

            expect(subject.current_user).to eq user
          end
        end

        context 'when user is NOT low risk' do
          let(:low_risk) { false }

          it 'prevents the user from logging in' do
            post(:create, params: params, session: {})

            expect(response).to render_template(:new)
            expect(flash[:alert]).to include 'Login failed. Please retry from your primary device and network'
            expect(subject.current_user).to be_nil
          end
        end

        context 'when request is for QA' do
          before do
            allow(Gitlab::Qa).to receive(:request?).and_return(true)
          end

          it 'skips token verification' do
            expect(Arkose::TokenVerificationService).not_to receive(:new)

            post(:create, params: params, session: {})
          end

          it 'logs in the user' do
            post(:create, params: params, session: {})

            expect(subject.current_user).to eq user
          end
        end
      end

      context 'when the user was not verified by Arkose' do
        before do
          allow_next_instance_of(Arkose::TokenVerificationService) do |instance|
            allow(instance).to receive(:execute).and_return(ServiceResponse.error(message: 'Captcha was not solved'))
          end
        end

        it 'prevents the user from logging in' do
          post(:create, params: params, session: {})

          expect(response).to render_template(:new)
          expect(flash[:alert]).to include 'Login failed. Please retry from your primary device and network'
          expect(subject.current_user).to be_nil
        end

        it 'sets gon variables' do
          Gon.clear

          post(:create, params: params, session: {})

          expect(response).to render_template(:new)
          expect(Gon.all_variables).not_to be_empty
        end
      end

      context 'when the user should be verified by Arkose but the request does not contain the arkose token' do
        it 'prevents the user from logging in' do
          post(:create, params: params.except!(:arkose_labs_token), session: {})

          expect(response).to render_template(:new)
          expect(flash[:alert]).to include 'Login failed. Please retry from your primary device and network'
          expect(subject.current_user).to be_nil
        end
      end
    end
  end
end
