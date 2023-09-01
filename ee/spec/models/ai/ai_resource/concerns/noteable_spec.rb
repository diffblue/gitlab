# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::AiResource::Concerns::Noteable, feature_category: :duo_chat do
  describe '#notes_with_limit' do
    let_it_be(:issue) { create(:issue) }
    let_it_be(:user) { create(:user) }
    let_it_be(:content_limit) { 1000 }

    subject(:notes) { Ai::AiResource::Issue.new(issue).notes_with_limit(user, notes_limit: content_limit) }

    context 'when user can see notes' do
      before do
        issue.project.add_guest(user)
      end

      context 'when there are notes for the noteable' do
        let_it_be(:note) { create(:note, noteable: issue, project: issue.project) }

        it 'returns an array with notes' do
          expect(notes).to contain_exactly(note.note)
        end

        context 'when there more notes for the noteable' do
          it 'returns an array with notes no longer than limit' do
            create(:note, noteable: issue, project: issue.project,
              note: '*' * content_limit, created_at: note.created_at + 1.minute)

            expect(notes).to be_an(Array)
            expect(notes).to contain_exactly(note.note)
          end
        end
      end
    end
  end
end
