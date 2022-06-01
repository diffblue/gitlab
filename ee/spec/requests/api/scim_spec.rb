# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Scim do
  let(:user) { create(:user) }
  let(:scim_token) { create(:scim_oauth_access_token, group: group) }
  let(:group) { identity.group }

  let_it_be(:password) { 'secret_pass' }
  let_it_be(:access_token) { 'secret_token' }

  before do
    stub_licensed_features(group_allowed_email_domains: true, group_saml: true)
    group.add_developer(user)
    create(:saml_provider, group: group, default_membership_role: Gitlab::Access::DEVELOPER)
  end

  def scim_api(url, token: true)
    api(url, user, version: '', oauth_access_token: token ? scim_token : nil)
  end

  shared_examples 'SCIM token authenticated' do
    context 'without token auth' do
      it 'responds with 401' do
        get scim_api("scim/v2/groups/#{group.full_path}/Users?filter=id eq \"#{identity.extern_uid}\"", token: false)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  shared_examples 'filtered params in errors' do
    it 'does not expose the password in error response' do
      expect(json_response.fetch('detail')).to include("\"password\"=>\"[FILTERED]\"")
    end

    it 'does not expose the access token in error response' do
      expect(json_response.fetch('detail')).to include("\"access_token\"=>\"[FILTERED]\"")
    end
  end

  shared_examples 'SCIM API endpoints' do
    describe 'GET api/scim/v2/groups/:group/Users' do
      it_behaves_like 'SCIM token authenticated'

      it 'responds with 404 for a non existent group' do
        get scim_api("scim/v2/groups/#{non_existing_record_id}/Users")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'responds with 404 for a group with no SAML SSO configuration' do
        group.saml_provider.destroy!

        get scim_api("scim/v2/groups/#{group.full_path}/Users")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'responds with paginated users when there is no filter' do
        get scim_api("scim/v2/groups/#{group.full_path}/Users")

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['Resources']).not_to be_empty
        expect(json_response['totalResults']).to eq(ScimIdentity.count)
      end

      it 'responds with an error for unsupported filters' do
        get scim_api("scim/v2/groups/#{group.full_path}/Users?filter=id ne \"#{identity.extern_uid}\"")

        expect(response).to have_gitlab_http_status(:precondition_failed)
      end

      context 'existing user matches filter' do
        it 'responds with 200' do
          get scim_api("scim/v2/groups/#{group.full_path}/Users?filter=id eq \"#{identity.extern_uid}\"")

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['Resources']).not_to be_empty
          expect(json_response['totalResults']).to eq(1)
        end

        it 'sets default values as required by the specification' do
          get scim_api(%{scim/v2/groups/#{group.full_path}/Users?filter=id eq "#{identity.extern_uid}"})

          expect(json_response['schemas']).to eq(['urn:ietf:params:scim:api:messages:2.0:ListResponse'])
          expect(json_response['itemsPerPage']).to eq(20)
          expect(json_response['startIndex']).to eq(1)
        end
      end

      context 'no user matches filter' do
        it 'responds with 200' do
          get scim_api("scim/v2/groups/#{group.full_path}/Users?filter=id eq \"nonexistent\"")

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['Resources']).to be_empty
          expect(json_response['totalResults']).to eq(0)
        end
      end
    end

    describe 'GET api/scim/v2/groups/:group/Users/:id' do
      it_behaves_like 'SCIM token authenticated'

      it 'responds with 404 for a non existent group' do
        get scim_api("scim/v2/groups/#{non_existing_record_id}/Users/#{identity.extern_uid}")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'responds with 404 for a group with no SAML SSO configuration' do
        group.saml_provider.destroy!

        get scim_api("scim/v2/groups/#{group.full_path}/Users/#{identity.extern_uid}")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'responds with 404 if there is no user' do
        get scim_api("scim/v2/groups/#{group.full_path}/Users/123")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'existing user' do
        it 'responds with 200' do
          get scim_api("scim/v2/groups/#{group.full_path}/Users/#{identity.extern_uid}")

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(identity.extern_uid)
        end
      end
    end

    describe 'POST api/scim/v2/groups/:group/Users' do
      it_behaves_like 'SCIM token authenticated'

      let_it_be(:post_params) do
        {
          externalId: 'test_uid',
          active: nil,
          userName: 'username',
          emails: [
            { primary: true, type: 'work', value: 'work@example.com' }
          ],
          name: { formatted: 'Test Name', familyName: 'Name', givenName: 'Test' },
          access_token: access_token,
          password: password
        }.to_query
      end

      it 'responds with 404 for a non existent group' do
        post scim_api("scim/v2/groups/#{non_existing_record_id}/Users?params=#{post_params}")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'responds with 404 for a group with no SAML SSO configuration' do
        group.saml_provider.destroy!

        post scim_api("scim/v2/groups/#{group.full_path}/Users?params=#{post_params}")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      context 'when a provisioning error occurs' do
        before do
          allow_next_instance_of(::EE::Gitlab::Scim::ProvisioningService) do |instance|
            allow(instance).to receive(:execute).and_return(::EE::Gitlab::Scim::ProvisioningResponse.new(status: :error))
          end

          post scim_api("scim/v2/groups/#{group.full_path}/Users?params=#{post_params}")
        end

        it_behaves_like 'filtered params in errors'
      end

      context 'without an existing user' do
        let(:new_user) { User.find_by_email('work@example.com') }
        let(:member) { GroupMember.find_by(user: new_user, group: group) }

        before do
          post scim_api("scim/v2/groups/#{group.full_path}/Users?params=#{post_params}")
        end

        it 'responds with 201' do
          expect(response).to have_gitlab_http_status(:created)
        end

        it 'has the user external ID' do
          expect(json_response['id']).to eq('test_uid')
        end

        it 'has the email' do
          expect(json_response['emails'].first['value']).to eq('work@example.com')
        end

        it 'created the user' do
          expect(new_user).not_to be_nil
        end

        it 'created the member with access level set in saml_provider' do
          expect(member.access_level).to eq(::Gitlab::Access::DEVELOPER)
        end

        it 'created the identity' do
          expect(group.scim_identities.with_extern_uid('test_uid').first).not_to be_nil
        end

        it 'marks the user as provisioned by the group' do
          expect(new_user.provisioned_by_group).to eq(group)
        end
      end

      context 'existing user' do
        let(:old_user) { create(:user, email: 'work@example.com') }

        before do
          create(:scim_identity, user: old_user, group: group, extern_uid: 'test_uid')
          group.add_guest(old_user)

          post scim_api("scim/v2/groups/#{group.full_path}/Users?params=#{post_params}")
        end

        it 'responds with 201' do
          expect(response).to have_gitlab_http_status(:created)
        end

        it 'has the user external ID' do
          expect(json_response['id']).to eq('test_uid')
        end

        it 'does not mark the user as provisioned' do
          expect(old_user.reload.provisioned_by_group).to be_nil
        end
      end

      it_behaves_like 'storing arguments in the application context for the API' do
        let(:expected_params) { { root_namespace: group.full_path_components.first } }

        subject { post scim_api("scim/v2/groups/#{group.full_path}/Users?params=#{post_params}") }
      end

      context 'with allowed domain setting switched on' do
        let(:new_user) { User.find_by_email('work@example.com') }
        let(:member) { GroupMember.find_by(user: new_user, group: group) }

        context 'with different domains' do
          before do
            create(:allowed_email_domain, group: group)
            post scim_api("scim/v2/groups/#{group.full_path}/Users?params=#{post_params}")
          end

          it 'created the user' do
            expect(new_user).not_to be_nil
          end

          it 'did not create member' do
            expect(member).to be_nil
          end

          context 'with invalid user params' do
            let(:post_params) do
              {
                externalId: 'test_uid',
                active: nil,
                userName: 'username',
                emails: [
                  { primary: nil, type: 'work', value: '' }
                ],
                name: { formatted: 'Test Name', familyName: 'Name', givenName: 'Test' }
              }.to_query
            end

            it 'returns user error' do
              expect(response).to have_gitlab_http_status(:precondition_failed)
              expect(json_response.fetch('detail')).to include("Email can't be blank")
            end
          end
        end

        context 'with matching domains' do
          before do
            create(:allowed_email_domain, group: group, domain: 'example.com')
            post scim_api("scim/v2/groups/#{group.full_path}/Users?params=#{post_params}")
          end

          it 'created the user' do
            expect(new_user).not_to be_nil
          end

          it 'created the member with access level set in saml_provider' do
            expect(member.access_level).to eq(::Gitlab::Access::DEVELOPER)
          end
        end
      end
    end

    describe 'PATCH api/scim/v2/groups/:group/Users/:id' do
      def call_patch_api(params)
        patch scim_api("scim/v2/groups/#{group.full_path}/Users/#{identity.extern_uid}?#{params}")
      end

      it_behaves_like 'SCIM token authenticated'

      it 'responds with 404 for a non existent group' do
        params = { Operations: [{ 'op': 'Replace', 'path': 'id', 'value': 'new_uid' }] }.to_query

        patch scim_api("scim/v2/groups/#{non_existing_record_id}/Users/#{identity.extern_uid}?#{params}")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'responds with 404 for a group with no SAML SSO configuration' do
        group.saml_provider.destroy!

        params = { Operations: [{ 'op': 'Replace', 'path': 'id', 'value': 'new_uid' }] }.to_query

        call_patch_api(params)

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'responds with 404 if there is no user' do
        patch scim_api("scim/v2/groups/#{group.full_path}/Users/123")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'deactivates the scim_identity' do
        params = { Operations: [{ 'op': 'Replace', 'path': 'active', 'value': 'False' }] }.to_query

        call_patch_api(params)

        expect(identity.reload.active).to be false
      end

      context 'with owner' do
        params = { Operations: [{ 'op': 'Replace', 'path': 'active', 'value': 'False' }] }.to_query

        before do
          group.add_owner(user)
          call_patch_api(params)
        end

        it 'responds with 412' do
          expect(response).to have_gitlab_http_status(:precondition_failed)
        end

        it 'returns the last group owner error' do
          expect(response.body).to include("Error updating #{user.name}")
        end

        it 'does not deactivate the identity' do
          expect(identity.reload.active).to be true
        end
      end

      context 'Reprovision user' do
        let_it_be(:params) { { Operations: [{ 'op': 'Replace', 'path': 'active', 'value': 'true' }] }.to_query }

        it 'activates the scim_identity' do
          identity.update!(active: false)

          call_patch_api(params)

          expect(identity.reload.active).to be true
        end

        it 'does not call reprovision service when identity is already active' do
          expect(::EE::Gitlab::Scim::ReprovisionService).not_to receive(:new)

          call_patch_api(params)
        end
      end

      context 'existing user' do
        context 'extern UID' do
          before do
            params = { Operations: [{ 'op': 'Replace', 'path': 'id', 'value': 'new_uid' }] }.to_query

            call_patch_api(params)
          end

          it 'responds with 204' do
            expect(response).to have_gitlab_http_status(:no_content)
          end

          it 'updates the extern_uid' do
            expect(identity.reload.extern_uid).to eq('new_uid')
          end
        end

        context 'user attributes' do
          context 'name' do
            before do
              params = { Operations: [{ 'op': 'Replace', 'path': 'name.formatted', 'value': 'new_name' }] }.to_query

              call_patch_api(params)
            end

            it 'responds with 204' do
              expect(response).to have_gitlab_http_status(:no_content)
            end

            it 'does not update the name' do
              expect(user.reload.name).not_to eq('new_name')
            end

            it 'responds with an empty response' do
              expect(response.body).to eq('')
            end
          end

          context 'email' do
            before do
              params = { Operations: [{ 'op': 'Replace', 'path': 'emails[type eq "work"].value', 'value': 'new@mail.com' }] }.to_query

              call_patch_api(params)
            end

            it 'does not update the email' do
              expect(user.reload.unconfirmed_email).not_to eq('new@mail.com')
            end

            it 'responds with 204' do
              expect(response).to have_gitlab_http_status(:no_content)
            end
          end

          context 'userName' do
            before do
              params = { Operations: [{ 'op': 'Replace', 'path': 'userName', 'value': 'new_username' }] }.to_query

              call_patch_api(params)
            end

            it 'responds with 204' do
              expect(response).to have_gitlab_http_status(:no_content)
            end

            it 'does not update the username' do
              expect(user.reload.username).not_to eq('new_username')
            end

            it 'responds with an empty response' do
              expect(response.body).to eq('')
            end
          end
        end
      end
    end

    describe 'DELETE /scim/v2/groups/:group/Users/:id' do
      context 'existing user' do
        before do
          delete scim_api("scim/v2/groups/#{group.full_path}/Users/#{identity.extern_uid}")
        end

        it 'responds with 204' do
          expect(response).to have_gitlab_http_status(:no_content)
        end

        it 'responds with an empty response' do
          expect(response.body).to eq('')
        end

        it 'deactivates the identity' do
          expect(identity.reload.active).to be false
        end
      end

      context 'with owner' do
        before do
          group.add_owner(user)
          delete scim_api("scim/v2/groups/#{group.full_path}/Users/#{identity.extern_uid}")
        end

        it 'responds with 412' do
          expect(response).to have_gitlab_http_status(:precondition_failed)
        end

        it 'returns the last group owner error' do
          expect(response.body).to include("Could not remove #{user.name} from #{group.name}. Cannot remove last group owner.")
        end

        it 'does not deactivate the identity' do
          expect(identity.reload.active).to be true
        end
      end

      it 'responds with 404 if there is no user' do
        delete scim_api("scim/v2/groups/#{group.full_path}/Users/123")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'responds with 404 for a non existent group' do
        delete scim_api("scim/v2/groups/#{non_existing_record_id}/Users/#{identity.extern_uid}")

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'responds with 404 for a group with no SAML SSO configuration' do
        group.saml_provider.destroy!

        delete scim_api("scim/v2/groups/#{group.full_path}/Users/#{identity.extern_uid}")

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  context 'user with an alphanumeric extern_uid' do
    let(:identity) { create(:scim_identity, user: user, extern_uid: generate(:username)) }

    it_behaves_like 'SCIM API endpoints'
  end

  context 'user with an email extern_uid' do
    let(:identity) { create(:scim_identity, user: user, extern_uid: user.email) }

    it_behaves_like 'SCIM API endpoints'
  end
end
