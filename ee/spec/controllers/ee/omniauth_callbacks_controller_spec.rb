# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OmniauthCallbacksController, type: :controller, feature_category: :authentication_and_authorization do
  include LoginHelpers
  include EE::GeoHelpers

  describe '#ldap' do
    let_it_be(:extern_uid) { 'my-uid' }
    let_it_be(:provider) { :ldap }
    let_it_be(:user) { create(:omniauth_user, extern_uid: extern_uid, provider: provider) }

    before do
      mock_auth_hash(provider.to_s, extern_uid, user.email)
      stub_omniauth_provider(provider, context: request)
    end

    context 'when sign in fails' do
      before do
        subject.response = ActionDispatch::Response.new

        allow(subject).to receive(:params)
          .and_return(ActionController::Parameters.new(username: user.username))

        stub_omniauth_failure(
          OmniAuth::Strategies::LDAP.new(nil),
          'invalid_credentials',
          OmniAuth::Strategies::LDAP::InvalidCredentialsError.new('Invalid credentials for ldap')
        )
      end

      it 'audits provider failed login when licensed' do
        stub_licensed_features(extended_audit_events: true)
        expect { subject.failure }.to change { AuditEvent.count }.by(1)
      end

      it 'does not audit provider failed login when unlicensed' do
        stub_licensed_features(extended_audit_events: false)
        expect { subject.failure }.not_to change { AuditEvent.count }
      end
    end
  end

  describe '#saml' do
    describe 'after sign in with Geo sites with separate URLs' do
      let(:last_request_id) { 'ONELOGIN_4fee3b046395c4e751011e97f8900b5273d56685' }
      let(:mock_saml_response) { File.read('spec/fixtures/authentication/saml_response.xml') }
      let_it_be(:primary_node) { create(:geo_node, :primary) }
      let_it_be(:secondary_node) { create(:geo_node) }

      before do
        session['last_authn_request_id'] = last_request_id
        stub_omniauth_saml_config(enabled: true, auto_link_saml_user: true, allow_single_sign_on: ['saml'],
                                  providers: [mock_saml_config])
        mock_auth_hash_with_saml_xml('saml', +'my-uid', user_email, mock_saml_response)
        request.env['devise.mapping'] = Devise.mappings[:user]
        request.env['omniauth.auth'] = Rails.application.env_config['omniauth.auth']
        stub_current_geo_node(primary_node)
      end

      context 'when the user initially visited the Geo secondary site' do
        def user_anonymously_visited_a_non_root_path_at_secondary_site
          session[::Gitlab::Geo::SIGN_IN_VIA_GEO_SITE_ID] = secondary_node.id
          allow(subject).to receive(:stored_location_for).and_return('/dashboard')
        end

        before do
          user_anonymously_visited_a_non_root_path_at_secondary_site
        end

        context 'on sign up' do
          let(:user_email) { 'test@example.com' }

          before do
            stub_omniauth_setting(block_auto_created_users: false)
          end

          it 'redirects to relative root path at the secondary site' do
            post :saml, params: { SAMLResponse: mock_saml_response }

            expect(response).to redirect_to("#{secondary_node.url}dashboard")
          end

          context 'when feature flag geo_fix_redirect_after_saml_sign_in is disabled' do
            before do
              stub_feature_flags(geo_fix_redirect_after_saml_sign_in: false)
            end

            it 'redirects to relative root path at the current site' do
              post :saml, params: { SAMLResponse: mock_saml_response }

              expect(response).to redirect_to('/dashboard')
            end
          end
        end

        context 'on sign in' do
          let_it_be(:user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'saml') }
          let(:user_email) { user.email }

          it 'redirects to relative root path at the secondary site' do
            post :saml, params: { SAMLResponse: mock_saml_response }

            expect(response).to redirect_to("#{secondary_node.url}dashboard")
          end

          context 'when feature flag geo_fix_redirect_after_saml_sign_in is disabled' do
            before do
              stub_feature_flags(geo_fix_redirect_after_saml_sign_in: false)
            end

            it 'redirects to relative root path at the current site' do
              post :saml, params: { SAMLResponse: mock_saml_response }

              expect(response).to redirect_to('/dashboard')
            end
          end
        end
      end

      context 'when the user initially visited the Geo primary site' do
        def user_anonymously_visited_a_non_root_path_at_primary_site
          allow(subject).to receive(:stored_location_for).and_return('/dashboard')
        end

        before do
          user_anonymously_visited_a_non_root_path_at_primary_site
        end

        context 'on sign up' do
          let(:user_email) { 'test@example.com' }

          before do
            stub_omniauth_setting(block_auto_created_users: false)
          end

          it 'redirects to relative root path at the current site' do
            post :saml, params: { SAMLResponse: mock_saml_response }

            expect(response).to redirect_to('/dashboard')
          end

          context 'when feature flag geo_fix_redirect_after_saml_sign_in is disabled' do
            before do
              stub_feature_flags(geo_fix_redirect_after_saml_sign_in: false)
            end

            it 'redirects to relative root path at the current site' do
              post :saml, params: { SAMLResponse: mock_saml_response }

              expect(response).to redirect_to('/dashboard')
            end
          end
        end

        context 'on sign in' do
          let_it_be(:user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'saml') }
          let(:user_email) { user.email }

          it 'redirects to relative root path at the current site' do
            post :saml, params: { SAMLResponse: mock_saml_response }

            expect(response).to redirect_to('/dashboard')
          end

          context 'when feature flag geo_fix_redirect_after_saml_sign_in is disabled' do
            before do
              stub_feature_flags(geo_fix_redirect_after_saml_sign_in: false)
            end

            it 'redirects to relative root path at the current site' do
              post :saml, params: { SAMLResponse: mock_saml_response }

              expect(response).to redirect_to('/dashboard')
            end
          end
        end
      end
    end
  end
end
