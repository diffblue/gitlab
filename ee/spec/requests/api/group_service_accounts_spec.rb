# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupServiceAccounts, :aggregate_failures, feature_category: :user_management do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }
  let(:service_account_user) { create(:user, :service_account) }

  before do
    service_account_user.provisioned_by_group_id = group.id
    service_account_user.save!
  end

  describe "POST /groups/:id/service_accounts" do
    subject(:perform_request) { post api("/groups/#{group_id}/service_accounts", user) }

    context 'when the feature is licensed' do
      before do
        stub_licensed_features(service_accounts: true)
      end

      context 'when current user is an owner' do
        before do
          group.add_owner(user)
        end

        context 'when the group exists' do
          let(:group_id) { group.id }

          it "creates user with user type service_account_user" do
            perform_request

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['username']).to start_with("service_account_group_#{group_id}")
            expect(json_response.keys).to match_array(%w[id username name])
          end

          it "returns bad request when service returns bad request" do
            allow_next_instance_of(::Namespaces::ServiceAccounts::CreateService) do |service|
              allow(service).to receive(:execute).and_return(
                ServiceResponse.error(message: message, reason: :bad_request)
              )
            end

            perform_request

            expect(response).to have_gitlab_http_status(:bad_request)
          end
        end

        context 'when the group does not exist' do
          let(:group_id) { non_existing_record_id }

          it "returns error" do
            perform_request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when user is not an owner' do
        let(:group_id) { group.id }

        before do
          group.add_maintainer(user)
        end

        it "returns error" do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'without authentication' do
        let(:group_id) { group.id }

        it "returns error" do
          post api("/groups/#{group_id}/service_accounts")

          expect(response).to have_gitlab_http_status(:unauthorized)
        end
      end
    end

    context 'when the feature is not licensed' do
      let(:group_id) { group.id }

      before do
        stub_licensed_features(service_accounts: false)
        group.add_owner(user)
      end

      it "returns error" do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe "POST /groups/:id/service_accounts/:user_id/personal_access_tokens" do
    let(:name) { 'new pat' }
    let(:expires_at) { 3.days.from_now.to_date.to_s }
    let(:scopes) { %w[api read_user] }
    let(:params) { { name: name, scopes: scopes, expires_at: expires_at } }

    subject(:perform_request) do
      post(
        api("/groups/#{group_id}/service_accounts/#{service_account_user.id}/personal_access_tokens", user),
        params: params)
    end

    context 'when the feature is licensed' do
      let(:group_id) { group.id }

      before do
        stub_licensed_features(service_accounts: true)
      end

      context 'when user is an owner' do
        before do
          group.add_owner(user)
        end

        context 'when the group exists' do
          it 'creates personal access token for the user' do
            perform_request

            expect(response).to have_gitlab_http_status(:created)
            expect(json_response['name']).to eq(name)
            expect(json_response['scopes']).to eq(scopes)
            expect(json_response['expires_at']).to eq(expires_at)
            expect(json_response['id']).to be_present
            expect(json_response['created_at']).to be_present
            expect(json_response['active']).to be_truthy
            expect(json_response['revoked']).to be_falsey
            expect(json_response['token']).to be_present
          end

          context 'when an error is thrown by the model' do
            let(:group_id) { group.id }
            let(:error_message) { 'error message' }
            let!(:admin_personal_access_token) { create(:personal_access_token, :admin_mode, user: create(:admin)) }

            before do
              allow_next_instance_of(::PersonalAccessTokens::CreateService) do |create_service|
                allow(create_service).to receive(:execute).and_return(
                  ServiceResponse.error(message: error_message)
                )
              end
            end

            it 'returns the error' do
              perform_request

              expect(response).to have_gitlab_http_status(:unprocessable_entity)
              expect(json_response['message']).to eq(error_message)
            end
          end

          context 'when target user does not belong to group' do
            before do
              service_account_user.provisioned_by_group_id = nil
              service_account_user.save!
            end

            it 'returns error' do
              perform_request

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context 'when target user is not service accounts' do
            let(:regular_user) { create(:user) }

            before do
              regular_user.provisioned_by_group_id = group.id
              regular_user.save!
            end

            it 'returns bad request error' do
              post api(
                "/groups/#{group_id}/service_accounts/#{regular_user.id}/personal_access_tokens", user
              ), params: params

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end

        context 'when group does not exist' do
          let(:group_id) { non_existing_record_id }

          it "returns error" do
            perform_request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when user is not an owner' do
        before do
          group.add_maintainer(user)
        end

        it 'returns error' do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end

      context 'without authentication' do
        it 'returns error' do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when feature is not licensed' do
      let(:group_id) { group.id }

      before do
        stub_licensed_features(service_accounts: false)
        group.add_owner(user)
      end

      it 'returns error' do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'POST /personal_access_tokens/:token_id/rotate' do
    let(:token) { create(:personal_access_token, user: service_account_user) }

    subject(:perform_request) do
      post api(
        "/groups/#{group_id}/service_accounts/#{service_account_user.id}/personal_access_tokens/#{token.id}/rotate",
        user
      )
    end

    context 'when the feature is licensed' do
      let(:group_id) { group.id }

      before do
        stub_licensed_features(service_accounts: true)
      end

      context 'when user is an owner' do
        before do
          group.add_owner(user)
        end

        context 'when the group exists' do
          it 'revokes the token' do
            perform_request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response['token']).not_to eq(token.token)
            expect(json_response['expires_at']).to eq((Date.today + 1.week).to_s)
          end

          context 'when service raises an error' do
            let(:error_message) { 'boom!' }

            before do
              allow_next_instance_of(PersonalAccessTokens::RotateService) do |service|
                allow(service).to receive(:execute).and_return(ServiceResponse.error(message: error_message))
              end
            end

            it 'returns error message' do
              perform_request

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(json_response['message']).to eq("400 Bad request - #{error_message}")
            end
          end

          context 'when token does not exist' do
            let(:invalid_path) do
              # rubocop:disable Layout/LineLength
              "/groups/#{group_id}/service_accounts/#{service_account_user.id}/personal_access_tokens/#{non_existing_record_id}/rotate"
              # rubocop:enable Layout/LineLength
            end

            it 'returns not found' do
              post api(invalid_path, user)

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context 'when token does not belong to service account user' do
            before do
              token.user = create(:user)
              token.save!
            end

            it 'returns bad request' do
              perform_request

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context 'when target user does not belong to group' do
            before do
              service_account_user.provisioned_by_group_id = nil
              service_account_user.save!
            end

            it 'returns error' do
              perform_request

              expect(response).to have_gitlab_http_status(:not_found)
            end
          end

          context 'when target user is not service accounts' do
            let(:regular_user) { create(:user) }

            before do
              regular_user.provisioned_by_group_id = group.id
              regular_user.save!
              token.user = regular_user
              token.save!
            end

            it 'returns bad request error' do
              post api(
                "/groups/#{group_id}/service_accounts/#{regular_user.id}/personal_access_tokens/#{token.id}/rotate",
                user
              )

              expect(response).to have_gitlab_http_status(:bad_request)
            end
          end
        end

        context 'when group does not exist' do
          let(:group_id) { non_existing_record_id }

          it "returns error" do
            perform_request

            expect(response).to have_gitlab_http_status(:not_found)
          end
        end
      end

      context 'when user is not an owner' do
        it 'throws error' do
          perform_request

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when the feature is not licensed' do
      let(:group_id) { group.id }

      before do
        stub_licensed_features(service_accounts: false)
        group.add_owner(user)
      end

      it "returns error" do
        perform_request

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
