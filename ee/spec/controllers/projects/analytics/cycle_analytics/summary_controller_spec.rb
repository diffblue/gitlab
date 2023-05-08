# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Analytics::CycleAnalytics::SummaryController, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  let(:params) { { namespace_id: project.namespace.to_param, project_id: project.to_param, created_after: '2010-01-01', created_before: '2020-01-02' } }

  before do
    sign_in(user)
  end

  describe 'GET "time_summary"' do
    let_it_be(:first_mentioned_in_commit_at) { Date.new(2015, 1, 1) }
    let_it_be(:closed_at) { Date.new(2015, 2, 1) }

    let_it_be(:closed_issue) do
      create(:issue, project: project, created_at: closed_at, closed_at: closed_at).tap do |issue|
        issue.metrics.update!(first_mentioned_in_commit_at: first_mentioned_in_commit_at)
      end
    end

    subject { get :time_summary, params: params }

    context 'when cycle_analytics_for_projects feature is available' do
      before do
        stub_licensed_features(cycle_analytics_for_projects: true, cycle_analytics_for_groups: true)

        Analytics::CycleAnalytics::DataLoaderService.new(group: group, model: Issue).execute

        project.add_reporter(user)
      end

      it 'succeeds' do
        subject

        expect(response).to be_successful
      end

      it 'returns correct value' do
        expected_cycle_time = (closed_at - first_mentioned_in_commit_at).to_i

        subject

        expect(json_response.last["value"].to_i).to eq(expected_cycle_time)
      end

      context 'when analytics_disabled features are disabled' do
        it 'renders 404' do
          project.add_reporter(user)
          project.project_feature.update!(analytics_access_level: ProjectFeature::DISABLED)

          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when user is not part of the project' do
      it 'renders 404' do
        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the feature is not available' do
      it 'renders 404' do
        project.add_reporter(user)

        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
