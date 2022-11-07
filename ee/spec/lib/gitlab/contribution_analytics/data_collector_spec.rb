# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ContributionAnalytics::DataCollector do
  let_it_be(:group) { create(:group) }
  let_it_be(:project1) { create(:project, group: group) }
  let_it_be(:project2) { create(:project, group: group) }

  describe 'date range filters' do
    it 'filters the date range' do
      # before the range
      create(:event, :pushed, project: project1, target: nil, created_at: 2.years.ago)
      # after the range
      create(:event, :pushed, project: project1, target: nil, created_at: Date.today)
      # in the range
      create(:event, :pushed, project: project1, target: nil, created_at: 1.year.ago)

      data_collector = described_class.new(group: group, from: 14.months.ago, to: 5.months.ago)

      all_event_count = data_collector.totals[:total_events].values.sum
      expect(all_event_count).to eq(1)
    end
  end

  describe '#totals' do
    it 'collects event counts grouped by users by calling #base_query' do
      user = create(:user)

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

  describe '#total_commit_count' do
    it 'computes the total number of commits' do
      other_group = create(:group)
      other_project = create(:project, group: other_group)

      event1 = create(:event, :pushed, project: project1, target: nil)
      event2 = create(:event, :pushed, project: project2, target: nil)
      event3 = create(:event, :pushed, project: other_project, target: nil)

      create(:push_event_payload, event: event1, commit_count: 2)
      create(:push_event_payload, event: event2, commit_count: 3)
      create(:push_event_payload, event: event3, commit_count: 7)

      data_collector = described_class.new(group: group)

      expect(data_collector.total_commit_count).to eq(5)
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
