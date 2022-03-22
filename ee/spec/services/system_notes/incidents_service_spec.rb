# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNotes::IncidentsService do
  include Gitlab::Routing

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:incident) { create(:incident, project: project, author: user) }
  let_it_be(:timeline_event) { create(:incident_management_timeline_event, project: project, incident: incident, author: author) }

  describe "#add_timeline_event" do
    subject { described_class.new(noteable: incident).add_timeline_event(timeline_event) }

    it_behaves_like 'a system note' do
      let(:noteable) { incident }
      let(:action) { 'timeline_event' }
    end

    it 'poses the correct text to the system note' do
      path = project_issues_incident_path(project, incident, anchor: "timeline_event_#{timeline_event.id}")
      expect(subject.note).to match("added an [incident timeline event](#{path})")
    end
  end
end
