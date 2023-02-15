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

  describe '#commenters' do
    shared_examples 'commenters' do
      it 'does not automatically include the noteable author' do
        expect(commenters).not_to include(noteable.author)
      end

      context 'with no user' do
        it 'contains a distinct list of non-internal note authors' do
          expect(commenters).to contain_exactly(commenter, another_commenter)
        end
      end

      context 'with non project member' do
        let(:current_user) { create(:user) }

        it 'contains a distinct list of non-internal note authors' do
          expect(commenters).to contain_exactly(commenter, another_commenter)
        end

        it 'does not include a commenter from another noteable' do
          expect(commenters).not_to include(other_noteable_commenter)
        end
      end
    end

    let_it_be(:commenter) { create(:user) }
    let_it_be(:another_commenter) { create(:user) }
    let_it_be(:internal_commenter) { create(:user) }
    let_it_be(:other_noteable_commenter) { create(:user) }

    let(:noteable) { create(:epic) }
    let(:current_user) {}
    let(:commenters) { noteable.commenters(user: current_user) }

    let!(:comments) { create_list(:note, 2, author: commenter, noteable: noteable, project: noteable.project) }
    let!(:more_comments) { create_list(:note, 2, author: another_commenter, noteable: noteable, project: noteable.project) }
    let!(:internal_comments) { create_list(:note, 2, author: internal_commenter, noteable: noteable, project: noteable.project, internal: true) }

    let!(:other_noteable_comments) { create_list(:note, 2, author: other_noteable_commenter, noteable: create(:epic, group: noteable.group)) }

    it_behaves_like 'commenters'

    context 'with reporter' do
      let(:current_user) { create(:user) }

      before do
        noteable.group.add_reporter(current_user)
      end

      it 'contains a distinct list of non-internal note authors' do
        expect(commenters).to contain_exactly(commenter, another_commenter, internal_commenter)
      end

      context 'with noteable author' do
        let(:current_user) { noteable.author }

        it 'contains a distinct list of non-internal note authors' do
          expect(commenters).to contain_exactly(commenter, another_commenter, internal_commenter)
        end
      end
    end
  end

  describe '#discussion_root_note_ids' do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:weight_event) { create(:resource_weight_event, issue: issue) }
    let_it_be(:regular_note) { create(:note, project: issue.project, noteable: issue) }
    let_it_be(:iteration_event) { create(:resource_iteration_event, issue: issue) }

    it 'includes weight and iteration synthetic notes' do
      discussions = issue.discussion_root_note_ids(notes_filter: UserPreference::NOTES_FILTERS[:all_notes]).map do |n|
        { table_name: n.table_name, id: n.id }
      end

      expect(discussions).to match(
        [
          a_hash_including(table_name: 'resource_weight_events', id: weight_event.id),
          a_hash_including(table_name: 'notes', id: regular_note.id),
          a_hash_including(table_name: 'resource_iteration_events', id: iteration_event.id)
        ])
    end

    it 'filters by comments only' do
      discussions = issue.discussion_root_note_ids(notes_filter: UserPreference::NOTES_FILTERS[:only_comments]).map do |n|
        { table_name: n.table_name, id: n.id }
      end

      expect(discussions).to match(
        [
          a_hash_including(table_name: 'notes', id: regular_note.id)
        ])
    end

    it 'filters by system notes only' do
      discussions = issue.discussion_root_note_ids(notes_filter: UserPreference::NOTES_FILTERS[:only_activity]).map do |n|
        { table_name: n.table_name, id: n.id }
      end

      expect(discussions).to match(
        [
          a_hash_including(table_name: 'resource_weight_events', id: weight_event.id),
          a_hash_including(table_name: 'resource_iteration_events', id: iteration_event.id)
        ])
    end
  end
end
