# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupServiceAccounts, :aggregate_failures, feature_category: :user_management do
  let(:user)  { create(:user) }
  let(:group) { create(:group) }

  describe "POST /groups/:id/service_accounts" do
    subject(:perform_request) { post api("/groups/#{group_id}/service_accounts", user) }

    context 'when the feature is licensed' do
      before do
        stub_licensed_features(service_accounts: true)
      end

      context 'when user is an owner' do
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
end
