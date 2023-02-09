# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceEvents::ChangeWeightService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }

  let(:issue) { create(:issue, weight: 3) }
  let(:created_at_time) { Time.utc(2019, 1, 1, 12, 30, 48, '123.123'.to_r) }

  subject { described_class.new(issue, user).execute }

  before do
    ResourceWeightEvent.new(issue: issue, user: user).save!
    issue.system_note_timestamp = created_at_time
  end

  it 'creates the expected event record' do
    expect { subject }.to change { ResourceWeightEvent.count }.by(1)

    record = ResourceWeightEvent.last
    expect_event_record(record, weight: 3, created_at: created_at_time)
  end

  context 'when weight is nil' do
    let(:issue) { create(:issue, weight: nil) }

    it 'creates an event record' do
      expect { subject }.to change { ResourceWeightEvent.count }.by(1)

      record = ResourceWeightEvent.last
      expect_event_record(record, weight: nil, created_at: created_at_time)
    end
  end

  context 'when there is no existing weight event record' do
    before do
      ResourceWeightEvent.delete_all
      issue.update!(weight: 5, updated_at: 10.seconds.ago)
    end

    it 'creates the expected event records' do
      prev_update_at = issue.previous_changes['updated_at']&.first

      expect { subject }.to change { ResourceWeightEvent.count }.by(2)

      record = ResourceWeightEvent.first
      expect_event_record(record, weight: 3, created_at: prev_update_at)

      record = ResourceWeightEvent.last
      expect_event_record(record, weight: 5, created_at: created_at_time)
    end

    it 'triggers note created subscription' do
      expect(GraphqlTriggers).to receive(:work_item_note_created).twice

      subject
    end
  end

  describe 'events tracking', :snowplow do
    context 'when resource is an issuable' do
      it 'tracks issue usage data counters' do
        expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_weight_changed_action)
                                                                           .with(author: user, project: issue.project)

        subject
      end
    end

    context 'when resource is a work item' do
      let(:work_item) { create(:work_item) }

      subject { described_class.new(work_item, user).execute }

      it 'tracks work item usage data counters' do
        expect(Gitlab::UsageDataCounters::WorkItemActivityUniqueCounter).to receive(:track_work_item_weight_changed_action).with(author: user)

        subject
      end
    end

    it_behaves_like 'issue_edit snowplow tracking' do
      let(:property) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_WEIGHT_CHANGED }
      let(:project) { issue.project }
    end
  end

  def expect_event_record(record, weight:, created_at:)
    expect(record.issue).to eq(issue)
    expect(record.user).to eq(user)
    expect(record.weight).to eq(weight)
    expect(record.created_at).to be_like_time(created_at)
  end
end
