# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ResourceMilestoneEvent, feature_category: :team_planning do
  describe 'scopes' do
    describe '.aliased_for_timebox_report', :freeze_time do
      let!(:event) { create(:resource_milestone_event, milestone: milestone) }

      let(:milestone) { create(:milestone) }
      let(:scope) { described_class.aliased_for_timebox_report.first }

      it 'returns correct values with aliased names', :aggregate_failures do
        expect(scope.event_type).to eq('timebox')
        expect(scope.id).to eq(event.id)
        expect(scope.issue_id).to eq(event.issue_id)
        expect(scope.value).to eq(milestone.id)
        expect(scope.action).to eq(event.action)
        expect(scope.created_at).to eq(event.created_at)
      end
    end
  end
end
