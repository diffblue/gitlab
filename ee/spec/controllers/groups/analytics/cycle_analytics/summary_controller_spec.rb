# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Analytics::CycleAnalytics::SummaryController do
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
        expect(instance.group).to eq(group)
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
end
