# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventCollection do
  let_it_be(:group) { create(:group) }
  let_it_be(:groups) { Group.where(id: group.id) }
  let_it_be(:project) { create(:project_empty_repo, group: group) }
  let_it_be(:projects) { Project.where(id: project.id) }

  before do
    stub_licensed_features(epics: true)
  end

  describe '#to_a' do
    context 'with group exclusive event types' do
      let(:subject) { described_class.new(projects, groups: groups, filter: EventFilter.new(EventFilter::EPIC)) }
      let!(:event) { create(:event, :epic_create_event, group: group) }

      it 'queries only group events for epic filter' do
        expect(subject).to receive(:group_events).with(no_args).and_call_original
        expect(subject).not_to receive(:project_events)

        expect(subject.to_a).to match_array(event)
      end
    end
  end
end
