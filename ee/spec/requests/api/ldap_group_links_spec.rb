# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::LdapGroupLinks, api: true, feature_category: :system_access do
  include ApiHelpers

  let(:owner) { create(:user) }
  let(:user) { create(:user) }
  let(:admin) { create(:admin) }

  let!(:group_with_ldap_links) do
    group = create(:group)
    group.ldap_group_links.create! cn: 'ldap-group1', group_access: Gitlab::Access::MAINTAINER, provider: 'ldap1'
    group.ldap_group_links.create! cn: 'ldap-group2', group_access: Gitlab::Access::MAINTAINER, provider: 'ldap2'
    group.ldap_group_links.create! cn: 'ldap-group3', group_access: Gitlab::Access::MAINTAINER, provider: 'ldap2'
    group.ldap_group_links.create! filter: '(uid=mary)', group_access: Gitlab::Access::DEVELOPER, provider: 'ldap2'
    group
  end

  let(:group_with_no_ldap_links) { create(:group) }

  before do
    group_with_ldap_links.add_owner owner
    group_with_ldap_links.add_member user, Gitlab::Access::DEVELOPER
    group_with_no_ldap_links.add_owner owner
  end

  describe "GET /groups/:id/ldap_group_links" do
    context "when unauthenticated" do
      it "returns authentication error" do
        get api("/groups/#{group_with_ldap_links.id}/ldap_group_links")

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when a less priviledged user" do
      it "returns forbidden" do
        get api("/groups/#{group_with_ldap_links.id}/ldap_group_links", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "when owner of the group" do
      it "returns ldap group links" do
        get api("/groups/#{group_with_ldap_links.id}/ldap_group_links", owner)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to(
          match([
                  a_hash_including('cn' => 'ldap-group1', 'provider' => 'ldap1'),
                  a_hash_including('cn' => 'ldap-group2', 'provider' => 'ldap2'),
                  a_hash_including('cn' => 'ldap-group3', 'provider' => 'ldap2'),
                  a_hash_including('cn' => nil, 'provider' => 'ldap2')
                ]))
      end

      it "returns error if no ldap group links found" do
        get api("/groups/#{group_with_no_ldap_links.id}/ldap_group_links", owner)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "POST /groups/:id/ldap_group_links" do
    shared_examples 'creates LDAP group link' do
      context "when unauthenticated" do
        it "returns authentication error" do
          params_test = params.merge( { group_access: GroupMember::GUEST, provider: 'ldap3' } )
          post api("/groups/#{group_with_ldap_links.id}/ldap_group_links"), params: params_test

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context "when a less priviledged user" do
        it "does not allow less priviledged user to add LDAP group link" do
          params_test = params.merge( { group_access: GroupMember::GUEST, provider: 'ldap3' } )
          expect do
            post api("/groups/#{group_with_ldap_links.id}/ldap_group_links", user), params: params_test
          end.not_to change { group_with_ldap_links.ldap_group_links.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context "when owner of the group" do
        it "returns ok and add ldap group link" do
          params_test = params.merge( { group_access: GroupMember::GUEST, provider: 'ldap3' } )
          expect do
            post api("/groups/#{group_with_ldap_links.id}/ldap_group_links", owner), params: params_test
          end.to change { group_with_ldap_links.ldap_group_links.count }.by(1)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['cn']).to eq(params_test[:cn])
          expect(json_response['filter']).to eq(params_test[:filter])
          expect(json_response['group_access']).to eq(params_test[:group_access])
          expect(json_response['provider']).to eq(params_test[:provider])
        end

        it "returns error if LDAP group link already exists" do
          params_test = params.merge( { group_access: GroupMember::GUEST, provider: 'ldap2' } )
          post api("/groups/#{group_with_ldap_links.id}/ldap_group_links", owner), params: params_test

          expect(response).to have_gitlab_http_status(:conflict)
        end

        it "returns a 400 error when CN or filter is not given" do
          params_test = { group_access: GroupMember::GUEST, provider: 'ldap1' }
          post api("/groups/#{group_with_ldap_links.id}/ldap_group_links", owner), params: params_test

          expect(response).to have_gitlab_http_status(:bad_request)
        end

        it "returns a 400 error when group access is not given" do
          params_test = params.merge( { provider: 'ldap1' } )
          post api("/groups/#{group_with_ldap_links.id}/ldap_group_links", owner), params: params_test

          expect(response).to have_gitlab_http_status(:bad_request)
        end

        it "returns a 422 error when group access is not valid" do
          params_test = params.merge( { group_access: 11, provider: 'ldap1' } )
          post api("/groups/#{group_with_ldap_links.id}/ldap_group_links", owner), params: params_test

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(json_response['error']).to eq('group_access does not have a valid value')
        end
      end
    end

    context "adding a group link via CN" do
      it_behaves_like 'creates LDAP group link' do
        let(:params) { { cn: 'ldap-group3' } }
      end
    end

    context "adding a group link via filter" do
      context "feature is available" do
        before do
          stub_licensed_features(ldap_group_sync_filter: true)
        end

        it_behaves_like 'creates LDAP group link' do
          let(:params) { { filter: '(uid=mary)' } }
        end
      end

      context 'feature is not available' do
        before do
          stub_licensed_features(ldap_group_sync_filter: false)
        end

        it 'returns 404' do
          post api("/groups/#{group_with_ldap_links.id}/ldap_group_links", owner), params: { filter: '(uid=mary)', group_access: GroupMember::GUEST, provider: 'ldap3' }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end

  describe 'DELETE /groups/:id/ldap_group_links/:cn' do
    context "when unauthenticated" do
      it "returns authentication error" do
        delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap-group1")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when a less priviledged user" do
      it "does not remove the LDAP group link" do
        expect do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap-group1", user)
        end.not_to change { group_with_ldap_links.ldap_group_links.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "when owner of the group" do
      it "removes ldap group link" do
        expect do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap-group1", owner)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { group_with_ldap_links.ldap_group_links.count }.by(-1)
      end

      it "returns 404 if LDAP group cn not used for a LDAP group link" do
        expect do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap-group1356", owner)
        end.not_to change { group_with_ldap_links.ldap_group_links.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /groups/:id/ldap_group_links/:provider/:cn' do
    context "when unauthenticated" do
      it "returns authentication error" do
        delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap2/ldap-group2")
        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context "when a less priviledged user" do
      it "does not remove the LDAP group link" do
        expect do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap2/ldap-group2", user)
        end.not_to change { group_with_ldap_links.ldap_group_links.count }

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context "when owner of the group" do
      it "returns 404 if LDAP group cn not used for a LDAP group link for the specified provider" do
        expect do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap1/ldap-group2", owner)
        end.not_to change { group_with_ldap_links.ldap_group_links.count }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it "removes ldap group link" do
        expect do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links/ldap2/ldap-group2", owner)

          expect(response).to have_gitlab_http_status(:no_content)
        end.to change { group_with_ldap_links.ldap_group_links.count }.by(-1)
      end
    end
  end

  describe 'DELETE /groups/:id/ldap_group_links' do
    shared_examples 'deletes LDAP group link' do
      context "when unauthenticated" do
        it "returns authentication error" do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links"), params: params
          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end

      context "when a less priviledged user" do
        it "does not remove the LDAP group link" do
          expect do
            delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links", user), params: params
          end.not_to change { group_with_ldap_links.ldap_group_links.count }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context "when owner of the group" do
        it "removes ldap group link" do
          expect do
            delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links", owner), params: params

            expect(response).to have_gitlab_http_status(:no_content)
          end.to change { group_with_ldap_links.ldap_group_links.count }.by(-1)
        end
      end
    end

    shared_examples 'group link is not found' do
      context "when owner of the group" do
        it "returns 404 if LDAP input not used for a LDAP group link" do
          expect do
            delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links", owner), params: params
          end.not_to change { group_with_ldap_links.ldap_group_links.count }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context "deleting a group link via CN and provider" do
      it_behaves_like 'deletes LDAP group link' do
        let(:params) { { cn: 'ldap-group3', provider: 'ldap2' } }
      end

      it_behaves_like 'group link is not found' do
        let(:params) { { cn: 'ldap-group1356', provider: 'ldap2' } }
      end
    end

    context "deleting a group link via filter and provider" do
      context "feature is available" do
        before do
          stub_licensed_features(ldap_group_sync_filter: true)
        end

        it_behaves_like 'deletes LDAP group link' do
          let(:params) { { filter: '(uid=mary)', provider: 'ldap2' } }
        end

        it_behaves_like 'group link is not found' do
          let(:params) { { filter: '(uid=mary3)', provider: 'ldap1' } }
        end
      end

      context 'feature is not available' do
        before do
          stub_licensed_features(ldap_group_sync_filter: false)
        end

        it 'returns 404' do
          delete api("/groups/#{group_with_ldap_links.id}/ldap_group_links", owner), params: { filter: '(uid=mary)', provider: 'ldap1' }

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
