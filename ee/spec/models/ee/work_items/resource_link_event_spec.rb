# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::WorkItems::ResourceLinkEvent, feature_category: :team_planning do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
  end

  describe 'scopes' do
    describe '.aliased_for_timebox_report', :freeze_time do
      let!(:event) { create(:resource_link_event, issue: issue, child_work_item: work_item) }

      let(:issue) { create(:issue) }
      let(:work_item) { create(:work_item) }
      let(:scope) { described_class.aliased_for_timebox_report.first }

      it 'returns correct values with aliased names', :aggregate_failures do
        expect(scope.event_type).to eq('link')
        expect(scope.id).to eq(event.id)
        expect(scope.issue_id).to eq(event.issue_id)
        expect(scope.value).to eq(event.child_work_item_id)
        expect(scope.action).to eq('add')
        expect(scope.created_at).to eq(event.created_at)
      end
    end
  end
end
