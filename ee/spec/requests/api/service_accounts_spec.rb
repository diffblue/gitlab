# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ServiceAccounts, :aggregate_failures, feature_category: :user_management do
  let(:user)  { create(:user) }
  let(:admin) { create(:admin) }

  describe "POST /service_accounts" do
    subject(:perform_request_as_admin) { post api("/service_accounts", admin, admin_mode: true) }

    context 'when feature is licensed' do
      before do
        stub_licensed_features(service_accounts: true)
      end

      context 'when user is an admin' do
        it "creates user with user type service_account_user" do
          perform_request_as_admin

          expect(response).to have_gitlab_http_status(:created)
          expect(json_response['username']).to start_with('service_account')
        end

        it 'returns bad request error when service returns bad request' do
          allow_next_instance_of(::Users::ServiceAccounts::CreateService) do |service|
            allow(service).to receive(:execute).and_return(
              ServiceResponse.error(message: message, reason: :bad_request)
            )
          end

          perform_request_as_admin

          expect(response).to have_gitlab_http_status(:bad_request)
        end
      end

      context 'when user is not an admin' do
        it "returns error" do
          post api("/service_accounts", user)

          expect(response).to have_gitlab_http_status(:forbidden)
        end
      end
    end

    context 'when licensed feature is not present' do
      it "returns error" do
        perform_request_as_admin

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
