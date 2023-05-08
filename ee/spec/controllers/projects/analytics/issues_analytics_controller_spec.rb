# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Analytics::IssuesAnalyticsController, feature_category: :team_planning do
  it_behaves_like 'issue analytics controller' do
    let_it_be(:user)  { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project1) { create(:project, :empty_repo, namespace: group) }
    let_it_be(:issue1) { create(:issue, project: project1, confidential: true) }
    let_it_be(:issue2) { create(:issue, :closed, project: project1) }

    before do
      group.add_owner(user)
      sign_in(user)
    end

    let(:params) { { namespace_id: group.to_param, project_id: project1.to_param } }

    describe 'GET #show' do
      before do
        stub_licensed_features(issues_analytics: true)
      end

      it_behaves_like 'tracking unique visits', :show do
        let(:request_params) { { namespace_id: project1.namespace, project_id: project1 } }
        let(:target_id) { 'p_analytics_issues' }
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        subject { get :show, params: request_params, format: :html }

        let(:request_params) { { namespace_id: project.namespace, project_id: project1 } }
        let(:category) { described_class.name }
        let(:action) { 'perform_analytics_usage_action' }
        let(:namespace) { group }
        let(:project) { project1 }
        let(:label) { 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly' }
        let(:property) { 'p_analytics_issues' }
      end
    end
  end
end
