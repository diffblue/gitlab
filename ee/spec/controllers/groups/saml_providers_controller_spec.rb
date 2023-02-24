# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SamlProvidersController, feature_category: :system_access do
  let(:saml_provider) { create(:saml_provider, group: group) }
  let(:group) { create(:group, :private, parent_id: nil) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  def stub_saml_config(enabled:)
    providers = enabled ? %i(group_saml) : []
    allow(Devise).to receive(:omniauth_providers).and_return(providers)
  end

  shared_examples '404 status' do
    it 'returns 404 status' do
      group.add_owner(user)

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'configuration is prevented' do
    describe 'GET #show' do
      subject { get :show, params: { group_id: group } }

      it_behaves_like '404 status'
    end

    describe 'POST #create' do
      subject { post :create, params: { group_id: group, saml_provider: { enabled: 'false' } } }

      it_behaves_like '404 status'
    end

    describe 'PUT #update' do
      subject { put :update, params: { group_id: group, saml_provider: { enabled: 'false' } } }

      it_behaves_like '404 status'
    end
  end

  context 'when per group saml is unlicensed' do
    before do
      stub_licensed_features(group_saml: false)
      stub_saml_config(enabled: true)
    end

    it_behaves_like 'configuration is prevented'
  end

  context 'when per group saml is unconfigured' do
    before do
      stub_licensed_features(group_saml: true)
      stub_saml_config(enabled: false)
    end

    it_behaves_like 'configuration is prevented'
  end

  context 'when per group saml feature is enabled' do
    before do
      stub_saml_config(enabled: true)
      stub_licensed_features(group_saml: true)
    end

    describe 'GET #show' do
      subject { get :show, params: { group_id: group } }

      it 'shows configuration page' do
        group.add_owner(user)

        subject

        expect(response).to render_template 'groups/saml_providers/show'
      end

      it 'has no SCIM token URL' do
        group.add_owner(user)

        subject

        expect(assigns(:scim_token_url)).to be_nil
      end

      it 'has the SCIM token URL when it exists' do
        create(:scim_oauth_access_token, group: group)
        group.add_owner(user)

        subject

        expect(assigns(:scim_token_url)).to eq("http://localhost/api/scim/v2/groups/#{group.full_path}")
      end

      context 'not on a top level group' do
        let(:group) { create(:group, :nested) }

        it_behaves_like '404 status'
      end

      context 'with unauthorized user' do
        it 'responds with 404' do
          group.add_developer(user)

          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    describe 'PUT #update' do
      subject do
        put :update, params:
          {
            group_id: group,
            saml_provider: {
              enforced_sso: 'true',
              default_membership_role: Gitlab::Access::MAINTAINER
            }
          }
      end

      before do
        group.add_owner(user)
      end

      it 'updates the settings' do
        expect do
          subject
          saml_provider.reload
        end.to change { saml_provider.enforced_sso? }.to(true)
        .and change { saml_provider.default_membership_role }.to(Gitlab::Access::MAINTAINER)
      end

      context 'enabling group managed when owner has linked identity' do
        subject { put :update, params: { group_id: group, saml_provider: { enforced_sso: 'true', enforced_group_managed_accounts: 'true' } } }

        before do
          create(:group_saml_identity, saml_provider: saml_provider, user: user)
        end

        context 'group_managed_accounts feature flag enabled' do
          before do
            stub_feature_flags(group_managed_accounts: true)
          end

          it 'updates the flags' do
            expect do
              subject
              saml_provider.reload
            end.to change { saml_provider.enforced_group_managed_accounts? }.to(true)
          end
        end

        context 'group_managed_accounts feature flag disabled' do
          before do
            stub_feature_flags(group_managed_accounts: false)
          end

          it 'does not update the setting' do
            expect do
              subject
              saml_provider.reload
            end.not_to change { saml_provider.enforced_group_managed_accounts? }.from(false)
          end
        end
      end

      context 'enabling group managed when owner has not linked identity' do
        subject { put :update, params: { group_id: group, saml_provider: { enforced_sso: 'true', enforced_group_managed_accounts: 'true' } } }

        before do
          stub_feature_flags(group_managed_accounts: true)
        end

        it 'does not update the flags' do
          expect do
            subject
            saml_provider.reload
          end.not_to change { saml_provider.enforced_group_managed_accounts? }
        end
      end
    end
  end
end
