# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceWeightEvent, feature_category: :team_planning, type: :model do
  let_it_be(:user1) { create(:user) }
  let_it_be(:user2) { create(:user) }

  let_it_be(:issue1) { create(:issue, author: user1) }
  let_it_be(:issue2) { create(:issue, author: user1) }
  let_it_be(:issue3) { create(:issue, author: user2) }

  it_behaves_like 'a resource event'
  it_behaves_like 'a resource event for issues'
  it_behaves_like 'a note for work item resource event'

  describe 'validations' do
    it { is_expected.not_to allow_value(nil).for(:issue) }
    it { is_expected.to allow_value(nil).for(:weight) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:issue) }
  end

  describe '.aliased_for_timebox_report', :freeze_time do
    let!(:event) { create(:resource_weight_event, issue: issue1) }

    let(:scope) { described_class.aliased_for_timebox_report.first }

    it 'returns correct values with aliased names', :aggregate_failures do
      expect(scope.event_type).to eq('weight')
      expect(scope.id).to eq(event.id)
      expect(scope.issue_id).to eq(event.issue_id)
      expect(scope.value).to eq(issue1.weight)
      expect(scope.action).to eq(nil)
      expect(scope.created_at).to eq(event.created_at)
    end
  end

  describe '.by_issue' do
    let_it_be(:event1) { create(:resource_weight_event, issue: issue1) }
    let_it_be(:event2) { create(:resource_weight_event, issue: issue2) }
    let_it_be(:event3) { create(:resource_weight_event, issue: issue1) }

    it 'returns the expected records for an issue with events' do
      events = described_class.by_issue(issue1)

      expect(events).to contain_exactly(event1, event3)
    end

    it 'returns the expected records for an issue with no events' do
      events = described_class.by_issue(issue3)

      expect(events).to be_empty
    end
  end

  describe '.created_after' do
    let!(:created_at1) { 1.day.ago }
    let!(:created_at2) { 2.days.ago }
    let!(:created_at3) { 3.days.ago }

    let!(:event1) { create(:resource_weight_event, issue: issue1, created_at: created_at1) }
    let!(:event2) { create(:resource_weight_event, issue: issue2, created_at: created_at2) }
    let!(:event3) { create(:resource_weight_event, issue: issue2, created_at: created_at3) }

    it 'returns the expected events' do
      events = described_class.created_after(created_at3)

      expect(events).to contain_exactly(event1, event2)
    end

    it 'returns no events if time is after last record time' do
      events = described_class.created_after(1.minute.ago)

      expect(events).to be_empty
    end
  end

  describe '#discussion_id' do
    let_it_be(:event) { create(:resource_weight_event, issue: issue1, created_at: Time.utc(2019, 12, 30)) }

    it 'returns the expected id' do
      allow(Digest::SHA1).to receive(:hexdigest)
                               .with("ResourceWeightEvent-#{event.id}-#{user1.id}")
                               .and_return('73d167c478')

      expect(event.discussion_id).to eq('73d167c478')
    end
  end
end
