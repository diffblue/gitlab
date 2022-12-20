# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::GeoAuthController, :geo, feature_category: :geo_replication do
  include EE::GeoHelpers

  # The Geo OAuth workflow depends on the OAuth application and the URL
  # defined on the Geo primary node, so we use let! instead of let here
  # to define a memoized helper method that is called in a `before` hook
  # doing the proper set up for us.
  let!(:primary_node) { create(:geo_node, :primary) }
  let(:secondary_node) { create(:geo_node) }
  let(:user) { create(:user) }
  let(:oauth_application) { secondary_node.oauth_application }
  let(:access_token) { create(:doorkeeper_access_token, application: oauth_application, resource_owner_id: user.id) }
  let(:login_state) { Gitlab::Geo::Oauth::LoginState.new(return_to: secondary_node.url).encode }

  describe 'GET auth' do
    before do
      stub_current_geo_node(secondary_node)
    end

    it 'redirects to root_url when state is invalid' do
      allow_next_instance_of(Gitlab::Geo::Oauth::LoginState) do |instance|
        allow(instance).to receive(:valid?).and_return(false)
      end

      get :auth, params: { state: login_state }

      expect(response).to redirect_to(root_url)
    end

    shared_examples "a valid redirect to to primary node's oauth endpoint" do
      it "redirects to primary node's oauth endpoint" do
        oauth_endpoint = Gitlab::Geo::Oauth::Session.new.authorize_url(redirect_uri: oauth_geo_callback_url, state: login_state)

        get :auth, params: { state: login_state }

        expect(response).to redirect_to(oauth_endpoint)
      end
    end

    context 'without a tampered header' do
      it_behaves_like "a valid redirect to to primary node's oauth endpoint"
    end

    context 'with a tampered HOST header' do
      before do
        request.headers['HOST'] = 'http://this.is.not.my.host'
      end

      it_behaves_like "a valid redirect to to primary node's oauth endpoint"
    end

    context 'with a tampered X-Forwarded-Host header' do
      before do
        request.headers['X-Forwarded-Host'] = 'http://this.is.not.my.host'
      end

      it_behaves_like "a valid redirect to to primary node's oauth endpoint"
    end
  end

  describe 'GET callback' do
    before do
      stub_current_geo_node(secondary_node)
    end

    context 'redirection' do
      before do
        allow_next_instance_of(Gitlab::Geo::Oauth::Session) do |instance|
          allow(instance).to receive(:get_token).and_return('token')
          allow(instance).to receive(:authenticate).and_return(user.attributes)
        end
      end

      it 'redirects to login screen if state is invalid' do
        allow_next_instance_of(Gitlab::Geo::Oauth::LoginState) do |instance|
          allow(instance).to receive(:valid?).and_return(false)
        end

        get :callback, params: { state: login_state }

        expect(response).to redirect_to(new_user_session_path)
      end

      context 'with a valid state' do
        shared_examples 'a valid redirect to redirect_url' do
          it "redirects to primary node's oauth endpoint" do
            get :callback, params: { state: login_state }

            expect(response).to redirect_to(secondary_node.uri.path)
          end
        end

        context 'without a tampered header' do
          it_behaves_like 'a valid redirect to redirect_url'
        end

        context 'with a tampered HOST header' do
          before do
            request.headers['HOST'] = 'this.is.not.my.host'
          end

          it_behaves_like 'a valid redirect to redirect_url'
        end

        context 'with a tampered X-Forwarded-Host header' do
          before do
            request.headers['X-Forwarded-Host'] = 'this.is.not.my.host'
          end

          it_behaves_like 'a valid redirect to redirect_url'
        end

        it 'does not display a flash message' do
          get :callback, params: { state: login_state }

          expect(controller).to set_flash[:alert].to(nil)
        end
      end
    end

    context 'invalid credentials' do
      let(:fake_response) { double('Faraday::Response', headers: {}, body: '', status: 403) }
      let(:oauth_error) { OAuth2::Error.new(OAuth2::Response.new(fake_response)) }

      before do
        allow_next_instance_of(Gitlab::Geo::Oauth::Session) do |instance|
          allow(instance).to receive(:get_token).and_return(access_token.token)
          allow(instance).to receive(:authenticate).and_raise(oauth_error)
        end
      end

      it 'handles invalid credentials error' do
        oauth_endpoint = Gitlab::Geo::Oauth::Session.new.authorize_url(redirect_uri: oauth_geo_callback_url, state: login_state)

        get :callback, params: { state: login_state }

        expect(response).to redirect_to(oauth_endpoint)
      end
    end

    context 'non-existent remote user' do
      render_views

      before do
        allow_next_instance_of(Gitlab::Geo::Oauth::Session) do |instance|
          allow(instance).to receive(:get_token).and_return('token')
          allow(instance).to receive(:authenticate).and_return(nil)
        end
      end

      it 'handles non-existent remote user error' do
        get :callback, params: { state: login_state }

        expect(response.code).to eq '200'
        expect(response.body).to include('Your account may have been deleted')
      end
    end

    context 'non-existent local user' do
      render_views

      before do
        allow_next_instance_of(Gitlab::Geo::Oauth::Session) do |instance|
          allow(instance).to receive(:get_token).and_return('token')
          allow(instance).to receive(:authenticate).and_return(id: non_existing_record_id)
        end
      end

      it 'handles non-existent local user error' do
        get :callback, params: { state: login_state }

        expect(response.code).to eq '200'
        expect(response.body).to include('Your account may have been deleted')
      end
    end
  end

  describe 'GET logout' do
    let(:logout_state) { Gitlab::Geo::Oauth::LogoutState.new(token: access_token.token).encode }

    render_views

    before do
      sign_in(user)
    end

    context 'when access_token is valid' do
      it 'logs out and redirects to the root_url' do
        get :logout, params: { state: logout_state }

        expect(assigns(:current_user)).to be_nil
        expect(response).to redirect_to root_url
      end
    end

    context 'when access_token is invalid' do
      it 'shows access token errors' do
        allow(Doorkeeper::AccessToken)
          .to receive(:by_token)
          .and_return(double(resource_owner_id: user.id, expired?: true))

        get :logout, params: { state: logout_state }

        expect(response.body).to include("There is a problem with the OAuth access_token: Token has expired")
      end
    end
  end
end
