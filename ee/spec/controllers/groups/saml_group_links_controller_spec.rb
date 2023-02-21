# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SamlGroupLinksController, feature_category: :system_access do
  let_it_be(:group) { create(:group) }
  let_it_be(:user)  { create(:user) }

  before_all do
    group.add_owner(user)
  end

  before do
    stub_licensed_features(group_saml: true, saml_group_sync: true)

    sign_in(user)
  end

  shared_examples 'checks authorization' do
    let_it_be(:saml_provider) { create(:saml_provider, group: group, enabled: true) }
    let_it_be(:params) { route_params }

    it 'renders 404 when the user is not authorized' do
      allow(controller).to receive(:can?).and_call_original
      allow(controller).to receive(:can?).with(user, :admin_saml_group_links, group).and_return(false)

      call_action

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe '#index' do
    let_it_be(:route_params) { { group_id: group } }

    subject(:call_action) { get :index, params: params }

    it_behaves_like 'checks authorization'

    context 'when the SAML provider is enabled' do
      let_it_be(:saml_provider) { create(:saml_provider, group: group, enabled: true) }
      let_it_be(:params) { route_params }

      it 'responds with 200' do
        call_action

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe '#create' do
    let_it_be(:route_params) { { group_id: group } }

    subject(:call_action) { post :create, params: params }

    it_behaves_like 'checks authorization'

    context 'when the SAML provider is enabled' do
      let_it_be(:saml_provider) { create(:saml_provider, group: group, enabled: true) }

      context 'with valid parameters' do
        let_it_be(:saml_group_name) { generate(:saml_group_name) }
        let_it_be(:params) { route_params.merge(saml_group_link: { access_level: ::Gitlab::Access::REPORTER, saml_group_name: saml_group_name }) }

        it 'responds with success' do
          expect(::Gitlab::Audit::Auditor)
            .to receive(:audit).with(
              hash_including(
                { name: "saml_group_links_created",
                  author: user,
                  scope: group,
                  target: group,
                  message: "SAML group links created. Group Name - #{saml_group_name}, Access Level - 20" })
            ).and_call_original

          call_action

          expect(response).to have_gitlab_http_status(:found)
          expect(flash[:notice]).to include('New SAML group link saved.')
          expect(AuditEvent.last.details[:custom_message]).to eq("SAML group links created. Group Name - #{saml_group_name}, Access Level - 20")
        end

        it 'creates the group link' do
          expect { call_action }.to change { group.saml_group_links.count }.by(1)
        end
      end

      context 'with missing parameters' do
        let_it_be(:params) { route_params.merge(saml_group_link: { access_level: ::Gitlab::Access::MAINTAINER }) }

        it 'displays an error' do
          call_action

          expect(response).to have_gitlab_http_status(:found)
          expect(flash[:alert]).to include("Could not create SAML group link: Saml group name can't be blank.")
        end
      end
    end
  end

  describe '#destroy' do
    let_it_be(:group_link) { create(:saml_group_link, group: group) }
    let_it_be(:route_params) { { group_id: group, id: group_link } }

    subject(:call_action) { delete :destroy, params: params }

    it_behaves_like 'checks authorization'

    context 'when the SAML provider is enabled' do
      let_it_be(:saml_provider) { create(:saml_provider, group: group, enabled: true) }

      context 'with an existent group link' do
        let_it_be(:params) { route_params }

        it 'responds with success' do
          expect(::Gitlab::Audit::Auditor)
            .to receive(:audit).with(
              hash_including(
                { name: "saml_group_links_removed",
                  author: user,
                  scope: group,
                  target: group,
                  message: "SAML group links removed. Group Name - #{group_link.saml_group_name}" })
            ).and_call_original

          call_action

          expect(response).to have_gitlab_http_status(:found)
          expect(flash[:notice]).to include('SAML group link was successfully removed.')
          expect(AuditEvent.last.details[:custom_message]).to eq("SAML group links removed. Group Name - #{group_link.saml_group_name}")
        end

        it 'removes the group link' do
          expect { call_action }.to change { group.saml_group_links.count }.by(-1)
        end
      end

      context 'with a non-existent group link' do
        let_it_be(:params) { { group_id: group, id: non_existing_record_id } }

        it 'renders 404' do
          call_action

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
