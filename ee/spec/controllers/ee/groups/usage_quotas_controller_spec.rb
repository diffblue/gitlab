# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UsageQuotasController, feature_category: :consumables_cost_management do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'GET #index' do
    subject(:request) { get :index, params: { group_id: group } }

    context 'when user has read_usage_quotas permission' do
      before do
        group.add_owner(user)
      end

      it_behaves_like 'seat count alert' do
        let(:namespace) { group }
      end

      it 'renders index with 200 status code' do
        request

        expect(response).to render_template('groups/usage_quotas/index')
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when user does not have read_usage_quotas permission' do
      before do
        group.add_maintainer(user)
      end

      it 'renders not_found' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #pending_members' do
    let(:feature_available) { true }

    subject(:request) { get :pending_members, params: { group_id: group } }

    before do
      group.add_owner(user)
      allow_next_found_instance_of(Group) do |group|
        allow(group).to receive(:user_cap_available?).and_return(feature_available)
      end
    end

    it 'renders the pending members index' do
      request
      expect(response).to render_template 'groups/usage_quotas/pending_members'
    end

    context 'when user cap feature is unavailable' do
      let(:feature_available) { false }

      it 'returns 404' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when user does not have permission for pending members index ' do
      before do
        group.add_developer(user)
      end

      it 'renders not_found' do
        request

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
