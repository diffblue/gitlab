# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SessionsController do
  include EE::GeoHelpers

  describe '#new' do
    let_it_be(:primary_node) { create(:geo_node, :primary) }
    let_it_be(:secondary_node) { create(:geo_node) }

    context 'on a Geo primary node' do
      before do
        stub_current_geo_node(primary_node)
      end

      shared_examples_for 'it does not set a session variable' do
        it 'does not set a session variable' do
          get new_user_session_path

          expect(session[::Gitlab::Geo::SIGN_IN_VIA_GEO_SITE_ID]).to be_nil
        end
      end

      context 'when feature flag geo_fix_redirect_after_saml_sign_in is enabled' do
        context 'when the request was proxied via a Geo secondary node' do
          before do
            stub_proxied_site(secondary_node)
          end

          context 'when the secondary node does not use a Unified URL' do
            it 'remembers the secondary node ID' do
              get new_user_session_path

              expect(session[::Gitlab::Geo::SIGN_IN_VIA_GEO_SITE_ID]).to eq(secondary_node.id)
            end
          end

          context 'when the secondary node uses a Unified URL' do
            let(:secondary_node) { create(:geo_node, url: primary_node.url) }

            it_behaves_like 'it does not set a session variable'
          end
        end

        context 'when the request was not proxied via a Geo secondary node' do
          before do
            allow(::Gitlab::Geo).to receive(:proxied_site).and_return(nil)
          end

          it_behaves_like 'it does not set a session variable'
        end
      end

      context 'when feature flag geo_fix_redirect_after_saml_sign_in is disabled' do
        before do
          stub_feature_flags(geo_fix_redirect_after_saml_sign_in: false)
        end

        context 'when the request was proxied via a Geo secondary node' do
          before do
            stub_proxied_site(secondary_node)
          end

          it_behaves_like 'it does not set a session variable'
        end
      end
    end
  end

  describe '#create' do
    let_it_be(:user) { create(:user, :unconfirmed) }

    subject(:sign_in) do
      post user_session_path(user: { login: user.username, password: user.password })
    end

    context 'when identity verification is turned off' do
      before do
        allow(::Users::EmailVerification::SendCustomConfirmationInstructionsService)
          .to receive(:enabled?).with(user.email).and_return(false)
      end

      it { is_expected.to redirect_to(root_path) }

      it 'does not set the `verification_user_id` session variable' do
        sign_in

        expect(request.session.has_key?(:verification_user_id)).to eq(false)
      end
    end

    context 'when identity verification is turned on' do
      before do
        allow(::Users::EmailVerification::SendCustomConfirmationInstructionsService)
          .to receive(:enabled?).with(user.email).and_return(true)
      end

      it { is_expected.to redirect_to(identity_verification_path) }

      it 'sets the `verification_user_id` session variable' do
        sign_in

        expect(request.session[:verification_user_id]).to eq(user.id)
      end

      context 'when the user is verified' do
        before do
          allow_next_found_instance_of(User) do |user|
            allow(user).to receive(:identity_verified?).and_return(true)
          end
        end

        it { is_expected.to redirect_to(root_path) }
      end

      context 'when the user is locked' do
        before do
          user.lock_access!
        end

        it { is_expected.not_to have_gitlab_http_status(:redirect) }
      end
    end
  end
end
