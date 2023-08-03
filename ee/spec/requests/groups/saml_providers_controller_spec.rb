# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SamlProvidersController, feature_category: :system_access do
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)

    stub_licensed_features(group_saml: true)
    allow(Devise).to receive(:omniauth_providers).and_return(%i[group_saml])
  end

  describe 'PUT update_microsoft_application' do
    context 'when the user is not a group owner' do
      before do
        allow(::Gitlab::Auth::Saml::Config).to receive(:microsoft_group_sync_enabled?).and_return(true)
      end

      it 'renders 404 not found' do
        put update_microsoft_application_group_saml_providers_path(group)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the user is a group owner' do
      before_all do
        group.add_owner(user)
      end

      it_behaves_like 'Microsoft application controller actions' do
        let(:path) { update_microsoft_application_group_saml_providers_path(group) }
      end
    end
  end
end
