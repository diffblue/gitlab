# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::RepositoryAnalyticsController, feature_category: :team_planning do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:feature_name) { :group_repository_analytics }

  before do
    sign_in(current_user)

    stub_licensed_features(feature_name => true)
  end

  describe 'GET show', :snowplow do
    subject { get :show, params: { group_id: group } }

    before do
      group.add_reporter(current_user)
    end

    specify { is_expected.to have_gitlab_http_status(:success) }

    it 'tracks a pageview event in snowplow' do
      subject

      expect_snowplow_event(
        category: 'Groups::Analytics::RepositoryAnalyticsController',
        action: 'show',
        label: 'group_id',
        value: group.id,
        namespace: group,
        user: current_user
      )
    end

    context 'when requesting a redirected path' do
      let(:redirect_route) { group.redirect_routes.create!(path: 'old-path') }
      let(:group_full_path) { redirect_route.path }

      before do
        allow(request).to receive(:original_fullpath).and_return("/#{group_full_path}")
      end

      it 'redirects to the canonical path' do
        get :show, params: { group_id: group_full_path }

        expect(response).to redirect_to(group_analytics_repository_analytics_path(group))
        expect(controller).to set_flash[:notice].to(/Please update any links and bookmarks/)
      end
    end

    context 'when license is missing' do
      before do
        stub_licensed_features(feature_name => false)
      end

      it { is_expected.to have_gitlab_http_status(:forbidden) }
    end

    context 'when the user has no access to the group' do
      before do
        current_user.group_members.delete_all
      end

      it { is_expected.to have_gitlab_http_status(:forbidden) }

      context 'when the user is an auditor' do
        let(:current_user) { create(:user, :auditor) }

        it { is_expected.to have_gitlab_http_status(:success) }
      end
    end
  end
end
