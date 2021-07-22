# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ContributionAnalytics::DataCollector do
  describe '#totals' do
    it 'collects event counts grouped by users by calling #base_query' do
      group = create(:group)
      user = create(:user)
      project1 = create(:project, group: group)
      project2 = create(:project, group: group)

      issue = create(:closed_issue, project: project1)
      mr = create(:merge_request, source_project: project2)

      create(:event, :closed, project: project1, target: issue, author: user)
      create(:event, :created, project: project2, target: mr, author: user)
      create(:event, :approved, project: project2, target: mr, author: user)
      create(:event, :closed, project: project2, target: mr, author: user)

      data_collector = described_class.new(group: group)
      expect(data_collector.totals).to eq({
        issues_closed: { user.id => 1 },
        issues_created: {},
        merge_requests_created: { user.id => 1 },
        merge_requests_merged: {},
        merge_requests_approved: { user.id => 1 },
        merge_requests_closed: { user.id => 1 },
        push: {},
        total_events: { user.id => 4 }
      })
    end
  end

  context 'deriving various counts from #raw_counts' do
    let(:raw_counts) do
      {
        [1, nil, Event.actions[:pushed]] => 2,
        [2, nil, Event.actions[:pushed]] => 2,
        [1, MergeRequest.name, Event.actions[:merged]] => 2,
        [4, MergeRequest.name, Event.actions[:merged]] => 2,
        [5, MergeRequest.name, Event.actions[:created]] => 0,
        [6, MergeRequest.name, Event.actions[:created]] => 1,
        [6, MergeRequest.name, Event.actions[:approved]] => 1,
        [6, MergeRequest.name, Event.actions[:closed]] => 1,
        [10, Issue.name, Event.actions[:closed]] => 10,
        [11, Issue.name, Event.actions[:closed]] => 11
      }
    end

    let(:data_collector) { described_class.new(group: Group.new) }

    before do
      allow(data_collector).to receive(:raw_counts).and_return(raw_counts)
    end

    describe 'extracts correct counts from raw_counts' do
      it 'for #push_by_author_count' do
        expect(data_collector.push_by_author_count).to eq({ 1 => 2, 2 => 2 })
      end

      it 'for #total_push_author_count' do
        expect(data_collector.total_push_author_count).to eq(2)
      end

      it 'for #total_push_count' do
        expect(data_collector.total_push_count).to eq(4)
      end

      it 'for #total_merge_requests_closed_count' do
        expect(data_collector.total_merge_requests_closed_count).to eq(1)
      end

      it 'for #total_merge_requests_created_count' do
        expect(data_collector.total_merge_requests_created_count).to eq(1)
      end

      it 'for #total_merge_requests_merged_count' do
        expect(data_collector.total_merge_requests_merged_count).to eq(4)
      end

      it 'for #total_merge_requests_approved_count' do
        expect(data_collector.total_merge_requests_approved_count).to eq(1)
      end

      it 'for #total_issues_closed_count' do
        expect(data_collector.total_issues_closed_count).to eq(21)
      end

      it 'handles empty result' do
        allow(data_collector).to receive(:raw_counts).and_return({})

        expect(data_collector.push_by_author_count).to eq({})
        expect(data_collector.total_push_author_count).to eq(0)
        expect(data_collector.total_push_count).to eq(0)
        expect(data_collector.total_merge_requests_created_count).to eq(0)
        expect(data_collector.total_merge_requests_merged_count).to eq(0)
        expect(data_collector.total_merge_requests_approved_count).to eq(0)
        expect(data_collector.total_issues_closed_count).to eq(0)
      end
    end
  end
end
