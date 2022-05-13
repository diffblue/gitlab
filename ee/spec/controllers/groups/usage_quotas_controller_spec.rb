# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UsageQuotasController do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
    group.add_owner(user)
  end

  describe 'Pushing the `updateStorageUsageDesign` feature flag to the frontend' do
    context 'when update_storage_usage_design is false' do
      it 'is disabled' do
        stub_feature_flags(update_storage_usage_design: false)
        get :index, params: { group_id: group }

        expect(Gon.features).not_to include('updateStorageUsageDesign' => true)
      end
    end

    context 'when update_storage_usage_design is true' do
      it 'is enabled' do
        stub_feature_flags(update_storage_usage_design: true)
        get :index, params: { group_id: group }

        expect(Gon.features).to include('updateStorageUsageDesign' => true)
      end
    end
  end

  describe 'GET #pending_members' do
    let(:feature_available) { true }

    before do
      allow_next_found_instance_of(Group) do |group|
        allow(group).to receive(:apply_user_cap?).and_return(feature_available)
      end
    end

    it 'renders the pending members index' do
      get :pending_members, params: { group_id: group }

      expect(response).to render_template 'groups/usage_quotas/pending_members'
    end

    context 'when user cap feature is unavailable' do
      let(:feature_available) { false }

      it 'returns 404' do
        get :pending_members, params: { group_id: group }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
