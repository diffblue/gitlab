# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Analytics::MergeRequestAnalyticsController, feature_category: :value_stream_management do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:feature_name) { :project_merge_request_analytics }

  before do
    sign_in(current_user)

    stub_licensed_features(feature_name => true)
  end

  describe 'GET #show' do
    subject { get :show, params: { namespace_id: group, project_id: project } }

    before do
      group.add_maintainer(current_user)
    end

    it { is_expected.to be_successful }

    it_behaves_like 'tracking unique visits', :show do
      let(:request_params) { { namespace_id: group, project_id: project } }
      let(:target_id) { 'p_analytics_merge_request' }
    end

    it_behaves_like 'Snowplow event tracking with RedisHLL context' do
      let(:category) { described_class.name }
      let(:action) { 'perform_analytics_usage_action' }
      let(:label) { 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly' }
      let(:property) { 'p_analytics_merge_request' }
      let(:namespace) { group }
      let(:user) { current_user }
    end

    context 'when license is missing' do
      before do
        stub_licensed_features(feature_name => false)
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when the user has no access to the group' do
      before do
        current_user.project_authorizations.delete_all
      end

      it { is_expected.to have_gitlab_http_status(:not_found) }
    end

    context 'when requesting HTML' do
      render_views

      before do
        get :show, params: { namespace_id: group, project_id: project }, format: :html
      end

      it 'renders the side navigation with the correct submenu set as active' do
        expect(response.body).to have_active_sub_navigation('Merge request')
      end
    end
  end
end
