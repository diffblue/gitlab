# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Microsoft::GraphClient, :aggregate_failures, feature_category: :system_access do
  let(:application) { create(:system_access_microsoft_application) }

  subject(:client) {  described_class.new(application) }

  describe '#store_new_access_token' do
    it 'successfully creates a new access token' do
      stub_post_request(
        response_body: File.read('ee/spec/fixtures/lib/microsoft/graph_client_responses/token.json'),
        response_status: 200
      )

      expect { client.store_new_access_token }.to change { ::SystemAccess::MicrosoftGraphAccessToken.count }.by(1)
    end

    it 'handles an invalid client ID' do
      stub_post_request(
        response_body: File.read('ee/spec/fixtures/lib/microsoft/graph_client_responses/invalid_client_id.json'),
        response_status: 400
      )

      expect(client.store_new_access_token).to start_with(
        "unauthorized_client: AADSTS700016: Application with identifier 'invalid_client_id' was not found"
      )
    end
  end

  describe '#user_group_membership_object_ids' do
    let!(:access_token) do
      create(:system_access_microsoft_graph_access_token,
        system_access_microsoft_application_id: application.id,
        expires_in: 3600)
    end

    context 'when the stored access token is valid' do
      it 'returns group object ids' do
        stub_get_request(
          url: client.user_group_membership_endpoint('user_id'),
          response_body: File.read('ee/spec/fixtures/lib/microsoft/graph_client_responses/user_group_membership.json'),
          response_status: 200
        )

        expect(client.user_group_membership_object_ids('user_id'))
          .to match_array(['1ae25d00-68e2-4116-8e52-1013675c9ffd'])
      end

      context 'when the user does not exist in Azure' do
        it 'returns an empty array' do
          stub_get_request(
            url: client.user_group_membership_endpoint('user_id'),
            response_body: File.read('ee/spec/fixtures/lib/microsoft/graph_client_responses/error.json'),
            response_status: 404
          )

          expect(client.user_group_membership_object_ids('user_id')).to match_array([])
        end
      end
    end

    context 'when the stored access token is expired' do
      let_it_be(:access_token_from_fixture) { 'superlongencodedjwthere' }

      before do
        access_token.update!(
          created_at: DateTime.now - 2.hours,
          updated_at: DateTime.now - 2.hours
        )

        stub_get_request(url: client.user_group_membership_endpoint('user_id'), response_body: '', response_status: 200)
      end

      it 'updates the access token' do
        expect(access_token.token).not_to eq(access_token_from_fixture)

        stub_post_request(
          response_body: File.read('ee/spec/fixtures/lib/microsoft/graph_client_responses/token.json'),
          response_status: 200
        )

        client.user_group_membership_object_ids('user_id')

        expect(access_token.reload.token).to eq(access_token_from_fixture)
      end
    end
  end

  def stub_post_request(response_body:, response_status:)
    WebMock.stub_request(:post, client.token_endpoint)
           .to_return(body: response_body, status: response_status, headers: { content_type: 'application/json' })
  end

  def stub_get_request(url:, response_body:, response_status:)
    WebMock.stub_request(:get, url)
           .to_return(body: response_body, status: response_status, headers: { content_type: 'application/json' })
  end
end
