# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::CycleAnalytics::SummaryController, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group, refind: true) { create(:group) }

  let(:params) { { group_id: group.full_path, created_after: '2010-01-01', created_before: '2010-01-02' } }

  before do
    stub_licensed_features(cycle_analytics_for_groups: true)

    group.add_reporter(user)
    sign_in(user)
  end

  shared_examples 'summary endpoint' do
    it 'succeeds' do
      subject

      expect(response).to be_successful
      expect(response).to match_response_schema('analytics/cycle_analytics/summary')
    end

    include_examples 'Value Stream Analytics data endpoint examples'
    include_examples 'group permission check on the controller level'
  end

  describe 'GET "show"' do
    subject { get :show, params: params }

    it_behaves_like 'summary endpoint'

    it 'passes the date filter to the query class' do
      expected_date_range = {
        created_after: Date.parse(params[:created_after]).at_beginning_of_day,
        created_before: Date.parse(params[:created_before]).at_end_of_day
      }

      expect(IssuesFinder).to receive(:new).with(user, hash_including(expected_date_range)).and_call_original

      subject
    end
  end

  describe 'GET "time_summary"' do
    subject { get :time_summary, params: params }

    it_behaves_like 'summary endpoint'

    it 'passes the group to RequestParams' do
      expect_next_instance_of(Gitlab::Analytics::CycleAnalytics::RequestParams) do |instance|
        expect(instance.namespace).to eq(group)
      end

      subject
    end

    it 'uses the aggregated VSA data collector' do
      # Ensure stage_hash_id is present for Lead Time and CycleTime
      Analytics::CycleAnalytics::DataLoaderService.new(group: group, model: Issue).execute

      # Calculating Cycle Time and Lead Time
      expect(Gitlab::Analytics::CycleAnalytics::Aggregated::DataCollector).to receive(:new).twice.and_call_original

      subject

      expect(response).to be_successful
    end
  end

  describe 'time series endpoints' do
    let(:params) { { group_id: group.full_path, created_after: 15.days.ago.to_date } }

    let_it_be(:created_at1) { 5.days.ago }
    let_it_be(:created_at2) { 10.days.ago }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:issue1) { create(:issue, project: project, created_at: created_at1, closed_at: created_at1 + 3.days) }
    let_it_be(:issue2) { create(:issue, project: project, created_at: created_at2, closed_at: created_at2 + 8.days) }

    before(:context) do
      issue1.metrics.update!(first_mentioned_in_commit_at: created_at1 + 2.days)
      issue2.metrics.update!(first_mentioned_in_commit_at: created_at2 + 7.days)
    end

    before do
      Analytics::CycleAnalytics::DataLoaderService.new(group: group, model: Issue).execute
    end

    describe 'GET "lead_times"' do
      subject { get :lead_times, params: params }

      it_behaves_like 'summary endpoint'

      it 'returns the daily average durations' do
        subject

        # duration between created_at and closed_at
        expect(json_response).to eq([{
          'average_duration_in_seconds' => (3.days.seconds + 8.days.seconds).fdiv(2),
          'date' => issue1.closed_at.to_date.to_s
        }])
      end
    end

    describe 'GET "cycle_times"' do
      subject { get :cycle_times, params: params }

      it_behaves_like 'summary endpoint'

      it 'returns the daily average durations' do
        subject

        # duration between first_mentioned_in_commit_at and closed_at
        expect(json_response).to eq([{
          'average_duration_in_seconds' => 2.days.seconds.fdiv(2),
          'date' => issue1.closed_at.to_date.to_s
        }])
      end
    end
  end
end
