# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::UsageQuotasController do
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
    group.add_owner(user)

    allow_next_found_instance_of(Group) do |group|
      allow(group).to receive(:additional_repo_storage_by_namespace_enabled?)
        .and_return(additional_repo_storage_by_namespace_enabled)
    end
  end

  describe 'Pushing the `additionalRepoStorageByNamespace` feature flag to the frontend' do
    context 'when additional_repo_storage_by_namespace_enabled is false' do
      let(:additional_repo_storage_by_namespace_enabled) { false }

      it 'is disabled' do
        get :index, params: { group_id: group }

        expect(Gon.features).to include('additionalRepoStorageByNamespace' => false)
      end
    end

    context 'when additional_repo_storage_by_namespace_enabled is true' do
      let(:additional_repo_storage_by_namespace_enabled) { true }

      it 'is enabled' do
        get :index, params: { group_id: group }

        expect(Gon.features).to include('additionalRepoStorageByNamespace' => true)
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
