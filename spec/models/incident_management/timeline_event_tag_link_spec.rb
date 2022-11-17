# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::TimelineEventTagLink do
  describe 'associations' do
    it { is_expected.to belong_to(:timeline_event) }
    it { is_expected.to belong_to(:timeline_event_tag) }
  end

  describe '#by_tag_ids scope' do
    let_it_be(:project) { create(:project) }
    let_it_be(:tag1) { create(:incident_management_timeline_event_tag, name: 'Test tag 1', project: project) }
    let_it_be(:tag2) { create(:incident_management_timeline_event_tag, name: 'Test tag 2', project: project) }
    let_it_be(:incident) { create(:incident, project: project) }

    let_it_be(:timeline_event) do
      create(:incident_management_timeline_event, project: project, incident: incident)
    end

    let_it_be(:tag_link1) do
      create(:incident_management_timeline_event_tag_link,
        timeline_event: timeline_event,
        timeline_event_tag: tag1
      )
    end

    let_it_be(:tag_link2) do
      create(:incident_management_timeline_event_tag_link,
        timeline_event: timeline_event,
        timeline_event_tag: tag2
      )
    end

    it 'returns the tag requested' do
      expect(described_class.by_tag_ids(tag1.id)).to contain_exactly(tag_link1)
    end
  end
end
