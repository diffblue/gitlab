# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EE::Noteable do
  subject(:klazz) { Class.new { include Noteable } }

  describe '.replyable_types' do
    it 'adds Epic to replyable_types after being included' do
      expect(klazz.replyable_types).to include("Epic")
    end

    it 'adds Vulnerability to replyable_types after being included' do
      expect(klazz.replyable_types).to include("Vulnerability")
    end
  end

  describe '#discussion_root_note_ids' do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:weight_event) { create(:resource_weight_event, issue: issue) }
    let_it_be(:regular_note) { create(:note, project: issue.project, noteable: issue) }
    let_it_be(:iteration_event) { create(:resource_iteration_event, issue: issue) }

    it 'includes weight and iteration synthetic notes' do
      discussions = issue.discussion_root_note_ids(notes_filter: UserPreference::NOTES_FILTERS[:all_notes]).map do |n|
        { table_name: n.table_name, discussion_id: n.discussion_id, id: n.id }
      end

      expect(discussions).to match(
        [
          a_hash_including(table_name: 'resource_weight_events', id: weight_event.id),
          a_hash_including(table_name: 'notes', discussion_id: regular_note.discussion_id),
          a_hash_including(table_name: 'resource_iteration_events', id: iteration_event.id)
        ])
    end

    it 'filters by comments only' do
      discussions = issue.discussion_root_note_ids(notes_filter: UserPreference::NOTES_FILTERS[:only_comments]).map do |n|
        { table_name: n.table_name, discussion_id: n.discussion_id, id: n.id }
      end

      expect(discussions).to match(
        [
          a_hash_including(table_name: 'notes', discussion_id: regular_note.discussion_id)
        ])
    end

    it 'filters by system notes only' do
      discussions = issue.discussion_root_note_ids(notes_filter: UserPreference::NOTES_FILTERS[:only_activity]).map do |n|
        { table_name: n.table_name, discussion_id: n.discussion_id, id: n.id }
      end

      expect(discussions).to match(
        [
          a_hash_including(table_name: 'resource_weight_events', id: weight_event.id),
          a_hash_including(table_name: 'resource_iteration_events', id: iteration_event.id)
        ])
    end
  end
end
