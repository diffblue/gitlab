# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Users, :aggregate_failures, feature_category: :user_profile do
  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }

  context 'updating name' do
    it_behaves_like 'PUT request permissions for admin mode' do
      let(:path) { "/users/#{user.id}" }
      let(:params) { { name: 'New Name' } }
    end

    shared_examples_for 'admin can update the name of a user' do
      it 'updates the user with new name' do
        put api("/users/#{user.id}", admin, admin_mode: true), params: { name: 'New Name' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['name']).to eq('New Name')
      end
    end

    context "when authenticated and ldap is enabled" do
      it "returns non-ldap user" do
        ldap_user = create :omniauth_user, provider: "ldapserver1"

        get api("/users", user), params: { skip_ldap: "true" }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an Array
        expect(json_response).not_to be_empty
        expect(json_response.map { |u| u['username'] })
          .not_to include(ldap_user.username)
      end
    end

    context 'when `disable_name_update_for_users` feature is available' do
      before do
        stub_licensed_features(disable_name_update_for_users: true)
      end

      context 'when the ability to update their name is disabled for users' do
        before do
          stub_application_setting(updating_name_disabled_for_users: true)
        end

        it_behaves_like 'admin can update the name of a user'
      end

      context 'when the ability to update their name is not disabled for users' do
        before do
          stub_application_setting(updating_name_disabled_for_users: false)
        end

        it_behaves_like 'admin can update the name of a user'
      end
    end

    context 'when `disable_name_update_for_users` feature is not available' do
      before do
        stub_licensed_features(disable_name_update_for_users: false)
      end

      it_behaves_like 'admin can update the name of a user'
    end
  end

  context 'extended audit events' do
    let_it_be(:user)  { create(:user) }
    let_it_be(:admin) { create(:admin) }

    before do
      stub_licensed_features(extended_audit_events: true)
    end

    describe "PUT /users/:id" do
      it_behaves_like 'PUT request permissions for admin mode' do
        let(:path) { "/users/#{user.id}" }
        let(:params) { { password: User.random_password } }
      end

      it "creates audit event when updating user with new password" do
        put api("/users/#{user.id}", admin, admin_mode: true), params: { password: User.random_password }

        expect(AuditEvent.count).to eq(1)
      end
    end

    describe 'POST /users/:id/block' do
      it_behaves_like 'POST request permissions for admin mode' do
        let(:path) { "/users/#{user.id}/block" }
        let(:params) { {} }
      end

      it 'creates audit event when blocking user' do
        expect do
          post api("/users/#{user.id}/block", admin, admin_mode: true)
        end.to change { AuditEvent.count }.by(1)
      end
    end

    describe 'POST /user/keys' do
      it 'creates audit event when user adds a new SSH key' do
        key = attributes_for(:key)

        expect do
          post api('/user/keys', user), params: key
        end.to change { AuditEvent.count }.by(1)
      end
    end

    describe 'POST /users/:id/keys' do
      it_behaves_like 'POST request permissions for admin mode' do
        let(:path) { "/users/#{user.id}/keys" }
        let(:params) { attributes_for(:key) }
      end

      it 'creates audit event when admin adds a new key for a user' do
        key = attributes_for(:key)

        expect do
          post api("/users/#{user.id}/keys", admin, admin_mode: true), params: key
        end.to change { AuditEvent.count }.by(1)
      end
    end
  end

  context 'shared_runners_minutes_limit' do
    describe "PUT /users/:id" do
      context 'when user is an admin' do
        it "updates shared_runners_minutes_limit" do
          expect do
            put api("/users/#{user.id}", admin, admin_mode: true), params: { shared_runners_minutes_limit: 133 }
          end.to change { user.reload.shared_runners_minutes_limit }
                   .from(nil).to(133)

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['shared_runners_minutes_limit']).to eq(133)
        end
      end

      context 'when user is not an admin' do
        it "cannot update their own shared_runners_minutes_limit" do
          expect do
            put api("/users/#{user.id}", user), params: { shared_runners_minutes_limit: 133 }
          end.not_to change { user.reload.shared_runners_minutes_limit }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end
  end

  context 'when auditor field is specified' do
    describe "PUT /users/:id" do
      context 'when user is an admin' do
        before do
          stub_licensed_features(auditor_user: true)
        end

        it "updates auditor status for the user" do
          expect do
            put api("/users/#{user.id}", admin, admin_mode: true), params: { auditor: true }
          end.to change { user.reload.auditor }
                   .from(false)
                   .to(true)

          expect(response).to have_gitlab_http_status(:success)
          expect(json_response['is_auditor']).to eq(true)
        end

        context "when licensed_feature is not available" do
          before do
            stub_licensed_features(auditor_user: false)
          end

          it "cannot update auditor status for the user" do
            expect do
              put api("/users/#{user.id}", admin, admin_mode: true), params: { auditor: true }
            end.not_to change { user.reload.auditor }

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end
      end

      context 'when user is not an admin' do
        before do
          stub_licensed_features(auditor_user: true)
        end

        it "cannot update auditor status for the user" do
          expect do
            put api("/users/#{user.id}", user), params: { auditor: true }
          end.not_to change { user.reload.auditor }

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    describe "POST /users/" do
      it_behaves_like 'POST request permissions for admin mode' do
        let(:path) { "/users" }
        let(:params) { attributes_for(:user).merge({ auditor: true }) }
      end

      context 'when user is an admin' do
        before do
          stub_licensed_features(auditor_user: true)
        end

        it "creates user with auditor status" do
          optional_attributes = { auditor: true }
          post api("/users", admin, admin_mode: true), params: attributes_for(:user).merge(optional_attributes)

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['is_auditor']).to eq(true)
        end

        context "when licensed_feature is not available" do
          before do
            stub_licensed_features(auditor_user: false)
          end

          it "cannot create user with auditor status" do
            optional_attributes = { auditor: true }
            post api("/users", admin, admin_mode: true), params: attributes_for(:user).merge(optional_attributes)

            expect(response).to have_gitlab_http_status(:bad_request)
            expect(json_response['is_auditor']).to be_nil
          end
        end
      end

      context 'when user is not an admin' do
        before do
          stub_licensed_features(auditor_user: true)
        end

        it "cannot create user with auditor status" do
          expect do
            post api("/users", user), params: { auditor: true }
          end.not_to change { user.reload.auditor }

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end
    end
  end

  context 'with group SAML' do
    before do
      stub_licensed_features(group_saml: true)
    end
    let(:saml_provider) { create(:saml_provider) }

    it_behaves_like 'POST request permissions for admin mode' do
      let(:path) { "/users" }
      let(:params) { attributes_for(:user, provider: 'group_saml', extern_uid: '67890', group_id_for_saml: saml_provider.group.id) }
    end

    it 'creates user with new identity' do
      post api("/users", admin, admin_mode: true), params: attributes_for(:user, provider: 'group_saml', extern_uid: '67890', group_id_for_saml: saml_provider.group.id)

      expect(response).to have_gitlab_http_status(:created)
      expect(json_response['identities'].first['extern_uid']).to eq('67890')
      expect(json_response['identities'].first['provider']).to eq('group_saml')
      expect(json_response['identities'].first['saml_provider_id']).to eq(saml_provider.id)
    end

    it 'creates user with new identity without sending reset password email' do
      post api("/users", admin, admin_mode: true), params: attributes_for(:user, reset_password: false, provider: 'group_saml', extern_uid: '67890', group_id_for_saml: saml_provider.group.id)

      expect(response).to have_gitlab_http_status(:created)

      new_user = User.find(json_response['id'])
      expect(new_user.recently_sent_password_reset?).to eq(false)
    end

    it 'updates user with new identity' do
      put api("/users/#{user.id}", admin, admin_mode: true), params: { provider: 'group_saml', extern_uid: '67890', group_id_for_saml: saml_provider.group.id }

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['identities'].first['extern_uid']).to eq('67890')
      expect(json_response['identities'].first['provider']).to eq('group_saml')
      expect(json_response['identities'].first['saml_provider_id']).to eq(saml_provider.id)
    end

    it 'fails to update user with nonexistent identity' do
      put api("/users/#{user.id}", admin, admin_mode: true), params: { provider: 'group_saml', extern_uid: '67890', group_id_for_saml: 15 }
      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']).to eq({ "identities.saml_provider_id" => ["can't be blank"] })
    end

    it 'fails to update user with nonexistent provider' do
      put api("/users/#{user.id}", admin, admin_mode: true), params: { provider: nil, extern_uid: '67890', group_id_for_saml: saml_provider.group.id }
      expect(response).to have_gitlab_http_status(:bad_request)
      expect(json_response['message']).to eq({ "identities.provider" => ["can't be blank"] })
    end

    it 'contains provisioned_by_group_id parameter' do
      user.update!(provisioned_by_group: saml_provider.group)
      get api("/users/#{user.id}", admin, admin_mode: true)

      expect(json_response).to have_key('provisioned_by_group_id')
    end
  end

  describe 'GET /api/users?saml_provider_id' do
    context 'querying users by saml provider id' do
      let(:group) { create(:group) }
      let(:saml_provider) { create(:saml_provider, group: group, enabled: true, enforced_sso: true) }

      it 'returns only users for the saml_provider_id' do
        saml_user = create(:user)
        create(:identity, provider: 'group_saml1', saml_provider_id: saml_provider.id, user: saml_user)
        non_saml_user = create(:user)

        get api("/users", user), params: { saml_provider_id: saml_provider.id }

        expect(response).to match_response_schema('public_api/v4/user/basics')
        expect(response).to include_pagination_headers
        expect(json_response.map { |u| u['id'] }).to include(saml_user.id)
        expect(json_response.map { |u| u['id'] }).not_to include(non_saml_user.id)
      end
    end
  end

  describe 'GET /user/:id' do
    context 'when authenticated' do
      context 'as an admin' do
        context 'and user has a plan', :saas do
          let!(:subscription) { create(:gitlab_subscription, :ultimate, namespace: user.namespace) }

          context 'and user is not a trial user' do
            it 'contains plan and trial' do
              get api("/users/#{user.id}", admin, admin_mode: true)

              expect(json_response).to include('plan' => 'ultimate', 'trial' => false)
            end
          end

          context 'and user is a trial user' do
            before do
              subscription.update!(trial: true)
            end

            it 'contains plan and trial' do
              get api("/users/#{user.id}", admin, admin_mode: true)

              expect(json_response).to include('plan' => 'ultimate', 'trial' => true)
            end
          end

          it 'contains is_auditor parameter' do
            get api("/users/#{user.id}", admin, admin_mode: true)

            expect(json_response).to have_key('is_auditor')
          end
        end

        context 'and user has no plan' do
          it 'returns `nil` for both plan and trial' do
            get api("/users/#{user.id}", admin, admin_mode: true)

            expect(json_response).to include('plan' => nil, 'trial' => false)
          end
        end
      end

      context 'as a user' do
        it 'does not contain plan and trial info' do
          get api("/users/#{user.id}", user)

          expect(json_response).not_to have_key('plan')
          expect(json_response).not_to have_key('trial')
        end

        it 'does not contain is_auditor parameter' do
          get api("/users/#{user.id}", user)

          expect(json_response).not_to have_key('is_auditor')
        end

        it 'does not contain provisioned_by_group_id parameter' do
          get api("/users/#{user.id}", user)

          expect(json_response).not_to have_key('provisioned_by_group_id')
        end
      end
    end

    context 'when not authenticated' do
      it 'does not contain plan and trial info' do
        get api("/users/#{user.id}")

        expect(json_response).not_to have_key('plan')
        expect(json_response).not_to have_key('trial')
      end
    end
  end
end
