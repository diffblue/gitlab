# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::ServiceAccountsController, feature_category: :user_management do
  let_it_be(:group) { create(:group) }

  let_it_be(:user) { create(:user) }

  before do
    group.add_developer(user)
    sign_in(user)
  end

  describe 'GET #index' do
    subject(:get_index) { get new_group_service_account_path(group) }

    context 'when `service_accounts_crud` feature flag is disabled' do
      before do
        stub_feature_flags(service_accounts_crud: false)
      end

      context 'when user is not a group owner' do
        it 'returns a 404 status code' do
          get_index

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user is a group owner' do
        before do
          group.add_owner(user)
        end

        it 'returns a 404 status code' do
          get_index

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when `service_accounts_crud` feature flag is enabled' do
      context 'when user is not a group owner' do
        it 'returns a 404 status code' do
          get_index

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when user is a group owner' do
        before do
          group.add_owner(user)
        end

        it 'returns a 200 status code' do
          get_index

          expect(response).to have_gitlab_http_status(:ok)
        end
      end
    end
  end
end
