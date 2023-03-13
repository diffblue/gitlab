# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicIssues::DestroyService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group, refind: true) { create(:group, :public) }
    let_it_be(:project, refind: true) { create(:project, group: group) }
    let_it_be(:epic, reload: true) { create(:epic, group: group) }
    let_it_be(:issue, reload: true) { create(:issue, project: project) }
    let_it_be(:epic_issue, reload: true) { create(:epic_issue, epic: epic, issue: issue) }

    subject { described_class.new(epic_issue, user).execute }

    context 'when epics feature is disabled' do
      before do
        project.add_guest(user)
        group.add_guest(user)
      end

      it 'returns an error' do
        is_expected.to eq(message: 'No Issue Link found', status: :error, http_status: 404)
      end

      it 'does not trigger issuableEpicUpdated' do
        expect(GraphqlTriggers).not_to receive(:issuable_epic_updated)

        subject
      end
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user has permissions to remove associations' do
        before do
          project.add_guest(user)
          group.add_guest(user)
        end

        it 'removes related issue' do
          expect { subject }.to change { EpicIssue.count }.from(1).to(0)
        end

        it 'returns success message' do
          is_expected.to eq(message: 'Relation was removed', status: :success)
        end

        it 'creates 2 system notes' do
          expect { subject }.to change { Note.count }.from(0).to(2)
        end

        it 'creates a note for epic correctly' do
          subject
          note = Note.find_by(noteable_id: epic.id, noteable_type: 'Epic')

          expect(note.note).to eq("removed issue #{issue.to_reference(epic.group)}")
          expect(note.author).to eq(user)
          expect(note.project).to be_nil
          expect(note.noteable_type).to eq('Epic')
          expect(note.system_note_metadata.action).to eq('epic_issue_removed')
        end

        it 'creates a note for issue correctly' do
          subject
          note = Note.find_by(noteable_id: issue.id, noteable_type: 'Issue')

          expect(note.note).to eq("removed from epic #{epic.to_reference(issue.project)}")
          expect(note.author).to eq(user)
          expect(note.project).to eq(issue.project)
          expect(note.noteable_type).to eq('Issue')
          expect(note.system_note_metadata.action).to eq('issue_removed_from_epic')
        end

        it 'counts an usage ping event' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_issue_removed)
            .with(author: user, namespace: group)

          subject
        end

        it 'triggers issuableEpicUpdated' do
          expect(GraphqlTriggers).to receive(:issuable_epic_updated).with(issue)

          subject
        end

        context 'refresh epic dates' do
          it 'calls UpdateDatesService' do
            expect(Epics::UpdateDatesService).to receive(:new).with([epic_issue.epic]).and_call_original

            subject
          end
        end
      end

      context 'user does not have permissions to remove associations' do
        it 'does not remove relation' do
          expect { subject }.not_to change { EpicIssue.count }.from(1)
        end

        it 'returns error message' do
          is_expected.to eq(message: 'No Issue Link found', status: :error, http_status: 404)
        end

        it 'does not counts an usage ping event' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).not_to receive(:track_epic_issue_removed)

          subject
        end

        it 'does not trigger issuableEpicUpdated' do
          expect(GraphqlTriggers).not_to receive(:issuable_epic_updated)

          subject
        end
      end
    end
  end
end
