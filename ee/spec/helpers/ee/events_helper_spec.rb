# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventsHelper do
  describe '#event_note_target_url' do
    subject { helper.event_note_target_url(event) }

    context 'for epic note events' do
      let_it_be(:group) { create(:group, :public) }
      let_it_be(:event) { create(:event, group: group) }

      it 'returns an epic url' do
        event.target = create(:note_on_epic, note: 'foo')

        expect(subject).to match("#{group.to_param}/-/epics/#{event.note_target.iid}#note_#{event.target.id}")
      end
    end

    context 'for vulnerability events' do
      let_it_be(:project) { create(:project) }
      let_it_be(:note) { create(:note_on_vulnerability, note: 'comment') }
      let_it_be(:event) { create(:event, project: project, target: note) }

      it 'returns an appropriate URL' do
        path = "#{project.full_path}/-/security/vulnerabilities/#{event.note_target_id}"
        fragment = "note_#{event.target.id}"

        expect(subject).to match("#{path}##{fragment}")
      end
    end
  end
end
