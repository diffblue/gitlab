# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'Analytics (JavaScript fixtures)', :sidekiq_inline do
  include CycleAnalyticsHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, namespace: group) }
  let_it_be(:user) { create(:user, :admin) }

  let(:issue) { create(:issue, project: project, created_at: 4.days.ago) }
  let(:issue_1) { create(:issue, project: project, created_at: 5.days.ago) }
  let(:issue_2) { create(:issue, project: project, created_at: 4.days.ago) }
  let(:issue_3) { create(:issue, project: project, created_at: 3.days.ago) }

  def prepare_cycle_analytics_data
    group.add_maintainer(user)
    project.add_maintainer(user)

    create_commit_referencing_issue(issue_1)
    create_commit_referencing_issue(issue_2)

    create_merge_request_closing_issue(user, project, issue_1)
    create_merge_request_closing_issue(user, project, issue_2)
    merge_merge_requests_closing_issue(user, project, issue_3)
  end

  describe Groups::Analytics::CycleAnalytics::SummaryController, type: :controller do
    render_views

    let(:params) { { created_after: 3.months.ago, created_before: Time.now, group_id: group.full_path } }

    def prepare_cycle_time_data
      issue.update!(created_at: 5.days.ago)
      issue.metrics.update!(first_mentioned_in_commit_at: 4.days.ago)
      issue.update!(closed_at: 3.days.ago)

      issue_1.update!(created_at: 8.days.ago)
      issue_1.metrics.update!(first_mentioned_in_commit_at: 6.days.ago)
      issue_1.update!(closed_at: 1.day.ago)
    end

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)

      prepare_cycle_analytics_data
      prepare_cycle_time_data

      sign_in(user)
    end

    it 'analytics/metrics/value_stream_analytics/summary.json' do
      get(:show, params: params, format: :json)

      expect(response).to be_successful
    end

    it 'analytics/metrics/value_stream_analytics/time_summary.json' do
      get(:time_summary, params: params, format: :json)

      expect(response).to be_successful
    end
  end
end
