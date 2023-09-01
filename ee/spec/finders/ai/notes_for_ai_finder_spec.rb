# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ai::NotesForAiFinder, feature_category: :duo_chat do
  let_it_be(:issue) { create(:issue) }
  let_it_be(:user) { create(:user) }

  subject(:finder) { described_class.new(user, resource: issue).execute }

  describe '#execute' do
    context 'when user cannot see notes' do
      it 'returns an empty relation' do
        create(:note, noteable: issue, project: issue.project)

        expect(finder).to be_empty
      end
    end

    context 'when user can see notes' do
      before do
        issue.project.add_guest(user)
      end

      context 'when there are no notes for the noteable' do
        it 'returns an empty relation' do
          expect(finder).to be_empty
        end
      end

      context 'when there are notes for the noteable' do
        let_it_be(:note) { create(:note, noteable: issue, project: issue.project) }

        it 'returns an array with notes' do
          expect(finder).to contain_exactly(note)
        end

        context 'when there internal notes for the noteable' do
          let_it_be(:internal_note) { create(:note, noteable: issue, project: issue.project, internal: true) }

          it 'returns an array without internal notes when user cannot see internal notes' do
            expect(finder).to contain_exactly(note)
          end

          it 'returns an array with internal notes when user can see internal notes' do
            issue.project.add_developer(user)

            expect(finder).to contain_exactly(note, internal_note)
          end
        end
      end
    end
  end
end
