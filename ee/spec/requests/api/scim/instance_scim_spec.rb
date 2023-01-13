# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Scim::InstanceScim, feature_category: :authentication_and_authorization do
  include LoginHelpers

  let(:user) { create(:user) }
  let(:scim_token) { create(:scim_oauth_access_token, group: nil) }

  before do
    stub_licensed_features(instance_level_scim: true)
    stub_basic_saml_config
    allow(Gitlab::Auth::OAuth::Provider).to receive(:providers).and_return([:saml])
  end

  shared_examples 'Not availble to SaaS customers' do
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

  shared_examples 'SCIM API endpoints' do
    describe 'GET api/scim/v2/application/Users' do
      let(:filter_query) { '' }

      subject(:api_request) do
        url = "scim/v2/application/Users#{filter_query}"
        get api(url, user, version: '', access_token: scim_token)
      end

      it_behaves_like 'Not availble to SaaS customers'
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

      it_behaves_like 'Not availble to SaaS customers'
      it_behaves_like 'Instance level SCIM license required'
      it_behaves_like 'SCIM token authenticated'
      it_behaves_like 'SAML SSO must be enabled'

      it 'responds with 403 when instance SAML SSO not configured' do
        allow(Gitlab::Auth::Saml::Config).to receive(:enabled?).and_return(false)

        api_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      context 'when there is no user associated with extern_uid' do
        let(:extern_uid) { non_existing_record_id }

        it 'responds with 404' do
          api_request

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when there is a user with extern_uid' do
        it 'responds with 200' do
          api_request

          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(identity.extern_uid)
        end
      end
    end
  end

  context 'when user with an alphanumeric extern_uid' do
    let!(:identity) { create(:scim_identity, user: user, extern_uid: generate(:username)) }

    it_behaves_like 'SCIM API endpoints'
  end

  context 'when user with an email extern_uid' do
    let!(:identity) { create(:scim_identity, user: user, extern_uid: user.email) }

    it_behaves_like 'SCIM API endpoints'
  end
end
