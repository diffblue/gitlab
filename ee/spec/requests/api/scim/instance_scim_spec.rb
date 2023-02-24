# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Scim::InstanceScim, feature_category: :system_access do
  include LoginHelpers

  let(:user) { create(:user) }
  let(:scim_token) { create(:scim_oauth_access_token, group: nil) }

  before do
    stub_licensed_features(instance_level_scim: true)
    stub_basic_saml_config
    allow(Gitlab::Auth::OAuth::Provider).to receive(:providers).and_return([:saml])
  end

  shared_examples 'Not available to SaaS customers' do
    context 'on GitLab.com' do
      before do
        allow(Gitlab).to receive(:com?).and_return(true)
      end

      it 'renders not found' do
        api_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'Instance level SCIM license required' do
    context 'when license is not enabled' do
      before do
        stub_licensed_features(instance_level_scim: false)
      end

      it 'returns not found error' do
        api_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'SCIM token authenticated' do
    context 'without token auth' do
      let(:scim_token) { nil }

      it 'responds with 401' do
        api_request

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end
  end

  shared_examples 'SAML SSO must be enabled' do
    it 'responds with 403 when instance SAML SSO not enabled' do
      allow(Gitlab::Auth::Saml::Config).to receive(:enabled?).and_return(false)

      api_request

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  shared_examples 'Invalid extern_uid returns 404' do
    context 'when there is no user associated with extern_uid' do
      let(:extern_uid) { non_existing_record_id }

      it 'responds with 404' do
        api_request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  shared_examples 'Filtered params in errors' do
    it 'does not expose the password in error response' do
      api_request

      expect(json_response.fetch('detail')).to include("\"password\"=>\"[FILTERED]\"")
    end

    it 'does not expose the access token in error response' do
      api_request

      expect(json_response.fetch('detail')).to include("\"access_token\"=>\"[FILTERED]\"")
    end
  end

  shared_examples 'SCIM API endpoints' do
    describe 'GET api/scim/v2/application/Users' do
      let(:filter_query) { '' }

      subject(:api_request) do
        url = "scim/v2/application/Users#{filter_query}"
        get api(url, user, version: '', access_token: scim_token)
      end

      it_behaves_like 'Not available to SaaS customers'
      it_behaves_like 'Instance level SCIM license required'
      it_behaves_like 'SCIM token authenticated'
      it_behaves_like 'SAML SSO must be enabled'

      it 'responds with paginated users when there is no filter' do
        api_request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['Resources']).not_to be_empty
        expect(json_response['totalResults']).to eq(ScimIdentity.count)
      end

      context 'when unsupported filters are used' do
        let(:filter_query) { "?filter=id ne \"#{identity.extern_uid}\"" }

        it 'responds with an error' do
          api_request

          expect(response).to have_gitlab_http_status(:precondition_failed)
        end
      end

      context 'when existing user matches filter' do
        let(:filter_query) { "?filter=id eq \"#{identity.extern_uid}\"" }

        it 'responds with 200' do
          api_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['Resources']).not_to be_empty
          expect(json_response['totalResults']).to eq(1)
        end

        it 'sets default values as required by the specification' do
          api_request

          expect(json_response['schemas']).to match_array(['urn:ietf:params:scim:api:messages:2.0:ListResponse'])
          expect(json_response['itemsPerPage']).to eq(20)
          expect(json_response['startIndex']).to eq(1)
        end
      end

      context 'when no user matches filter' do
        let(:filter_query) { "?filter=id eq \"#{non_existing_record_id}\"" }

        it 'responds with 200' do
          api_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['Resources']).to be_empty
          expect(json_response['totalResults']).to eq(0)
        end
      end
    end

    describe 'GET api/scim/v2/application/Users/:id' do
      let(:extern_uid) { identity.extern_uid }

      subject(:api_request) do
        url = "scim/v2/application/Users/#{extern_uid}"
        get api(url, user, version: '', access_token: scim_token)
      end

      it_behaves_like 'Not available to SaaS customers'
      it_behaves_like 'Instance level SCIM license required'
      it_behaves_like 'SCIM token authenticated'
      it_behaves_like 'SAML SSO must be enabled'
      it_behaves_like 'Invalid extern_uid returns 404'

      it 'responds with 403 when instance SAML SSO not configured' do
        allow(Gitlab::Auth::Saml::Config).to receive(:enabled?).and_return(false)

        api_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      context 'when there is a user with extern_uid' do
        it 'responds with 200' do
          api_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(identity.extern_uid)
        end
      end
    end

    describe 'POST api/scim/v2/application/Users' do
      let_it_be(:password) { User.random_password }
      let_it_be(:access_token) { 'secret_token' }

      let(:email) { 'work@example.com' }
      let(:external_uid) { 'test_uid' }
      let(:post_params) do
        {
          externalId: external_uid,
          active: nil,
          userName: 'username',
          emails: [
            { primary: true, type: 'work', value: email }
          ],
          name: { formatted: 'Test Name', familyName: 'Name', givenName: 'Test' },
          access_token: access_token,
          password: password
        }.to_query
      end

      subject(:api_request) do
        url = "scim/v2/application/Users?params=#{post_params}"
        post api(url, user, version: '', access_token: scim_token)
      end

      it_behaves_like 'Not available to SaaS customers'
      it_behaves_like 'Instance level SCIM license required'
      it_behaves_like 'SCIM token authenticated'
      it_behaves_like 'SAML SSO must be enabled'

      context 'without an existing user' do
        it 'responds with 201 and the new user attributes' do
          api_request

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['id']).to eq(external_uid)
          expect(json_response['emails'].first['value']).to eq(email)
        end
      end

      context 'when existing user' do
        it 'responds with 201 and the scim user attributes' do
          create(:user, email: email)

          api_request

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['id']).to eq(external_uid)
          expect(json_response['emails'].first['value']).to eq(email)
        end
      end

      context 'when a provisioning error occurs' do
        before do
          allow_next_instance_of(::EE::Gitlab::Scim::ProvisioningService) do |instance|
            allow(instance).to receive(:execute).and_return(
              ::EE::Gitlab::Scim::ProvisioningResponse.new(status: :error)
            )
          end
        end

        it_behaves_like 'Filtered params in errors'

        it 'returns a 412 response and error message' do
          api_request

          expect(response).to have_gitlab_http_status(:precondition_failed)
          expect(json_response.fetch('detail')).to match(/Error saving user/)
        end
      end

      context 'when a conflict occurs' do
        before do
          allow_next_instance_of(::EE::Gitlab::Scim::ProvisioningService) do |instance|
            allow(instance).to receive(:execute).and_return(
              ::EE::Gitlab::Scim::ProvisioningResponse.new(status: :conflict)
            )
          end
        end

        it_behaves_like 'Filtered params in errors'

        it 'returns a 409 response and error message' do
          api_request

          expect(response).to have_gitlab_http_status(:conflict)
          expect(json_response.fetch('detail')).to match(/Error saving user/)
        end
      end
    end

    describe 'PATCH api/scim/v2/application/Users/:id' do
      let(:extern_uid) { identity.extern_uid }
      let(:params) { '' }

      subject(:api_request) do
        url = "scim/v2/application/Users/#{extern_uid}?#{params}"
        patch api(url, user, version: '', access_token: scim_token)
      end

      it_behaves_like 'Not available to SaaS customers'
      it_behaves_like 'Instance level SCIM license required'
      it_behaves_like 'SCIM token authenticated'
      it_behaves_like 'SAML SSO must be enabled'
      it_behaves_like 'Invalid extern_uid returns 404'

      context 'when params update extern_uid for existing scim identity' do
        let(:new_extern_uid) { 'new_extern_uid' }
        let(:params) do
          {
            Operations: [{ 'op': 'Replace', 'path': 'id', 'value': new_extern_uid }]
          }.to_query
        end

        it 'responds with 204 and updates extern_uid' do
          api_request

          expect(response).to have_gitlab_http_status(:no_content)
          expect(identity.reload.extern_uid).to eq(new_extern_uid)
        end
      end

      context 'when params update other attributes on existing scim identity' do
        let(:params) do
          {
            Operations: [
              { 'op': 'Replace', 'path': 'name.formatted', 'value': 'new_name' },
              { 'op': 'Replace', 'path': 'emails[type eq "work"].value', 'value': 'new@mail.com' },
              { 'op': 'Replace', 'path': 'userName', 'value': 'new_username' }

            ]
          }.to_query
        end

        it 'responds with success but does not update the attributes' do
          api_request

          expect(response).to have_gitlab_http_status(:no_content)
          expect(user.reload.name).not_to eq('new_name')
          expect(user.reload.unconfirmed_email).not_to eq('new@mail.com')
          expect(user.reload.username).not_to eq('new_username')
        end
      end

      context 'when params are invalid' do
        let(:params) do
          { Garbage: 'params' }.to_query
        end

        it 'ignores the params and returns a success response' do
          api_request

          expect(response).to have_gitlab_http_status(:success)
        end
      end

      context 'when extern_uid update fails' do
        let(:new_extern_uid) { 'new_extern_uid' }
        let(:params) do
          {
            Operations: [{ 'op': 'Replace', 'path': 'id', 'value': new_extern_uid }]
          }.to_query
        end

        before do
          allow(ScimIdentity).to receive_message_chain(:for_instance, :with_extern_uid).and_return([identity])
          allow(identity).to receive(:update).and_return(false)
        end

        it 'returns an error' do
          api_request

          expect(response).to have_gitlab_http_status(:precondition_failed)
          expect(json_response.fetch('detail')).to match(/Error updating/)
          expect(identity.reload.extern_uid).to eq(extern_uid)
        end
      end

      context 'when deprovision fails' do
        let(:params) do
          {
            Operations: [{ 'op': 'Replace', 'path': 'active', 'value': 'false' }]
          }.to_query
        end

        before do
          allow_next_instance_of(::EE::Gitlab::Scim::DeprovisioningService) do |instance|
            allow(instance).to receive(:execute).and_raise(ActiveRecord::RecordInvalid)
          end
        end

        it 'returns an error' do
          api_request

          expect(response).to have_gitlab_http_status(:precondition_failed)
        end
      end

      context 'when reprovision fails' do
        let(:params) do
          {
            Operations: [{ 'op': 'Replace', 'path': 'active', 'value': 'true' }]
          }.to_query
        end

        before do
          allow_next_instance_of(::EE::Gitlab::Scim::ReprovisioningService) do |instance|
            allow(instance).to receive(:execute).and_raise(ActiveRecord::RecordInvalid)
          end
        end

        it 'returns an error' do
          identity.update!(active: false)

          api_request

          expect(response).to have_gitlab_http_status(:precondition_failed)
        end
      end

      context 'when param values deactivate scim identity' do
        let(:params) do
          {
            Operations: [{ 'op': 'Replace', 'path': 'active', 'value': 'False' }]
          }.to_query
        end

        it 'deactivates the scim_identity' do
          expect(identity.reload.active).to eq true

          api_request

          expect(identity.reload.active).to eq false
        end
      end

      context 'when param values reactivate scim identity' do
        let(:params) do
          {
            Operations: [{ 'op': 'Replace', 'path': 'active', 'value': 'true' }]
          }.to_query
        end

        it 'activates the scim_identity' do
          identity.update!(active: false)

          api_request

          expect(identity.reload.active).to be true
        end

        it 'does not call reprovision service when identity is already active' do
          expect(::EE::Gitlab::Scim::Group::ReprovisioningService).not_to receive(:new)

          api_request
        end
      end

      context 'when id param is missing from request' do
        let(:extern_uid) { '' }

        it 'returns method not allowed error' do
          api_request

          expect(response).to have_gitlab_http_status(:method_not_allowed)
        end
      end
    end

    describe 'DELETE /scim/v2/application/Users/:id' do
      let(:extern_uid) { identity.extern_uid }

      subject(:api_request) do
        url = "scim/v2/application/Users/#{extern_uid}"
        delete api(url, user, version: '', access_token: scim_token)
      end

      it_behaves_like 'Not available to SaaS customers'
      it_behaves_like 'Instance level SCIM license required'
      it_behaves_like 'SCIM token authenticated'
      it_behaves_like 'SAML SSO must be enabled'
      it_behaves_like 'Invalid extern_uid returns 404'

      context 'when existing user' do
        it 'responds with 204 and deactivates the scim identity' do
          api_request

          expect(response).to have_gitlab_http_status(:no_content)
          expect(identity.reload.active).to be false
        end
      end

      context 'when deprovision fails' do
        before do
          allow_next_instance_of(::EE::Gitlab::Scim::DeprovisioningService) do |instance|
            allow(instance).to receive(:execute).and_raise(ActiveRecord::RecordInvalid)
          end
        end

        it 'returns an error' do
          api_request

          expect(response).to have_gitlab_http_status(:precondition_failed)
        end
      end
    end
  end

  context 'when user with an alphanumeric extern_uid' do
    let!(:identity) { create(:scim_identity, user: user, extern_uid: generate(:username), group: nil) }

    it_behaves_like 'SCIM API endpoints'
  end

  context 'when user with an email extern_uid' do
    let!(:identity) { create(:scim_identity, user: user, extern_uid: user.email, group: nil) }

    it_behaves_like 'SCIM API endpoints'
  end
end
