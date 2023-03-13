# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicIssues::CreateService, feature_category: :portfolio_management do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:issue) { create(:issue, project: project) }
    let_it_be(:issue2) { create(:issue, project: project) }
    let_it_be(:issue3) { create(:issue, project: project) }
    let_it_be(:valid_reference) { issue.to_reference(full: true) }
    let_it_be(:epic, reload: true) { create(:epic, group: group) }

    def assign_issue(references)
      params = { issuable_references: references }

      described_class.new(epic, user, params).execute
    end

    shared_examples 'returns success' do
      let(:created_link) { EpicIssue.find_by!(issue_id: issue.id) }

      it 'creates a new relationship and updates epic' do
        expect(Epics::UpdateDatesService).to receive(:new).with([epic]).and_call_original
        expect { subject }.to change(EpicIssue, :count).by(1)

        expect(created_link).to have_attributes(epic: epic)
      end

      it 'orders the epic issue to the first place and moves the existing ones down' do
        existing_link = create(:epic_issue, epic: epic, issue: issue3)

        subject

        expect(created_link.relative_position).to be < existing_link.reload.relative_position
      end

      it 'returns success status and created links', :aggregate_failures do
        expect(subject.keys).to match_array([:status, :created_references])
        expect(subject[:status]).to eq(:success)
        expect(subject[:created_references].count).to eq(1)
      end

      it 'triggers issuableEpicUpdated' do
        expect(GraphqlTriggers).to receive(:issuable_epic_updated).with(issue)

        subject
      end

      describe 'async actions', :sidekiq_inline do
        it 'creates 1 system note for epic and 1 system note for issue' do
          expect { subject }.to change { Note.count }.by(2)
        end

        it 'creates a note for epic correctly' do
          subject
          note = Note.where(noteable_id: epic.id, noteable_type: 'Epic').last

          expect(note.note).to eq("added issue #{issue.to_reference(epic.group)}")
          expect(note.author).to eq(user)
          expect(note.project).to be_nil
          expect(note.noteable_type).to eq('Epic')
          expect(note.system_note_metadata.action).to eq('epic_issue_added')
        end

        it 'creates a note for issue correctly' do
          subject
          note = Note.find_by(noteable_id: issue.id, noteable_type: 'Issue')

          expect(note.note).to eq("added to epic #{epic.to_reference(issue.project)}")
          expect(note.author).to eq(user)
          expect(note.project).to eq(issue.project)
          expect(note.noteable_type).to eq('Issue')
          expect(note.system_note_metadata.action).to eq('issue_added_to_epic')
        end

        it 'records action on usage ping' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_issue_added)
            .with(author: user, namespace: group)

          subject
        end
      end
    end

    shared_examples 'returns an error' do
      it 'returns an error' do
        expect(subject).to eq(message: 'No matching issue found. Make sure that you are adding a valid issue URL.', status: :error, http_status: 404)
      end

      it 'no relationship is created' do
        expect { subject }.not_to change { EpicIssue.count }
      end

      it 'does not trigger issuableEpicUpdated' do
        expect(GraphqlTriggers).not_to receive(:issuable_epic_updated)

        subject
      end
    end

    context 'when epics feature is disabled' do
      subject { assign_issue([valid_reference]) }

      before do
        group.add_guest(user)
        project.add_guest(user)
      end

      include_examples 'returns an error'
    end

    context 'when epics feature is enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user has permissions to link the issue' do
        before do
          group.add_guest(user)
          project.add_guest(user)
        end

        context 'when the reference list is empty' do
          subject { assign_issue([]) }

          include_examples 'returns an error'

          it 'does not create a system note' do
            expect { assign_issue([]) }.not_to change { Note.count }
          end
        end

        context 'when there is an issue to relate' do
          context 'when shortcut for Issue is given' do
            subject { assign_issue([issue.to_reference]) }

            include_examples 'returns an error'
          end

          context 'when a full reference is given' do
            subject { assign_issue([valid_reference]) }

            include_examples 'returns success'

            it 'does not perform N + 1 queries', :request_store do
              allow(SystemNoteService).to receive(:epic_issue)
              allow(SystemNoteService).to receive(:issue_on_epic)

              # Extractor makes a permission check for each issue which messes up the query count check
              extractor = double
              allow(Gitlab::ReferenceExtractor).to receive(:new).and_return(extractor)
              allow(extractor).to receive(:reset_memoized_values)
              allow(extractor).to receive(:mentioned_user_ids)
              allow(extractor).to receive(:mentioned_group_ids)
              allow(extractor).to receive(:mentioned_project_ids)
              allow(extractor).to receive(:analyze)
              allow(extractor).to receive(:issues).and_return([issue])

              params = { issuable_references: [valid_reference] }
              control_count = ActiveRecord::QueryRecorder.new { described_class.new(epic, user, params).execute }.count

              user = create(:user)
              group = create(:group)
              project = create(:project, group: group)
              issues = create_list(:issue, 5, project: project)
              epic = create(:epic, group: group)
              group.add_guest(user)

              allow(extractor).to receive(:issues).and_return(issues)
              params = { issuable_references: issues.map { |i| i.to_reference(full: true) } }

              # threshold 24 because 6 queries are generated for each insert
              # (savepoint, find, exists, relative_position get, insert, release savepoint)
              # and we insert 5 issues instead of 1 which we do for control count
              expect { described_class.new(epic, user, params).execute }
                .not_to exceed_query_limit(control_count)
                .with_threshold(25)
            end
          end

          context 'when an issue link is given' do
            subject { assign_issue([Gitlab::Routing.url_helpers.namespace_project_issue_url(namespace_id: issue.project.namespace, project_id: issue.project, id: issue.iid)]) }

            include_examples 'returns success'
          end

          context 'when a link of an issue in a subgroup is given' do
            let_it_be(:subgroup) { create(:group, parent: group) }
            let_it_be(:project2) { create(:project, group: subgroup) }
            let_it_be(:issue) { create(:issue, project: project2) }

            subject { assign_issue([Gitlab::Routing.url_helpers.namespace_project_issue_url(namespace_id: issue.project.namespace, project_id: issue.project, id: issue.iid)]) }

            before do
              project2.add_guest(user)
            end

            include_examples 'returns success'
          end

          context 'when multiple valid issues are given' do
            let(:references) { [issue, issue2].map { |i| i.to_reference(full: true) } }

            subject { assign_issue(references) }

            let(:created_link1) { EpicIssue.find_by!(issue_id: issue.id) }
            let(:created_link2) { EpicIssue.find_by!(issue_id: issue2.id) }

            it 'creates new relationships' do
              expect { subject }.to change { EpicIssue.count }.by(2)

              expect(created_link1).to have_attributes(epic: epic)
              expect(created_link2).to have_attributes(epic: epic)
            end

            it 'places each issue at the start' do
              subject

              expect(created_link2.relative_position).to be < created_link1.relative_position
            end

            it 'orders the epic issues to the first place and moves the existing ones down' do
              existing_link = create(:epic_issue, epic: epic, issue: issue3)

              subject

              expect([created_link1, created_link2].map(&:relative_position))
                .to all(be < existing_link.reset.relative_position)
            end

            it 'returns success status and created links', :aggregate_failures do
              expect(subject.keys).to match_array([:status, :created_references])
              expect(subject[:status]).to eq(:success)
              expect(subject[:created_references].count).to eq(2)
            end

            it 'creates 2 system notes for each issue', :sidekiq_inline do
              expect { subject }.to change { Note.count }.from(0).to(4)
            end
          end
        end

        context 'when there are invalid references' do
          let_it_be(:epic) { create(:epic, confidential: true, group: group) }
          let_it_be(:valid_issue) { create(:issue, :confidential, project: project) }
          let_it_be(:invalid_issue1) { create(:issue, project: project) }
          let_it_be(:invalid_issue2) { create(:issue, project: project) }

          subject do
            assign_issue([invalid_issue1.to_reference(full: true),
                          valid_issue.to_reference(full: true),
                          invalid_issue2.to_reference(full: true)])
          end

          before do
            project.add_reporter(user)
          end

          it 'creates links only for valid references' do
            expect { subject }.to change { EpicIssue.count }.by(1)
          end

          it 'returns error status' do
            expect(subject).to eq(
              status: :error,
              http_status: 422,
              message: "#{invalid_issue1.to_reference} cannot be added: Cannot assign a confidential epic to a non-confidential issue. Make the issue confidential and try again. "\
                       "#{invalid_issue2.to_reference} cannot be added: Cannot assign a confidential epic to a non-confidential issue. Make the issue confidential and try again"
            )
          end
        end

        context "when assigning issuable which don't support epics" do
          let_it_be(:incident) { create(:incident, project: project) }

          subject { assign_issue([incident.to_reference(full: true)]) }

          include_examples 'returns an error'
        end
      end

      context 'when user does not have permissions to link the issue' do
        subject { assign_issue([valid_reference]) }

        include_examples 'returns an error'
      end

      context 'when assigning issue(s) to the same epic' do
        before do
          group.add_guest(user)
          project.add_guest(user)
          assign_issue([valid_reference])
          epic.reload
        end

        subject { assign_issue([valid_reference]) }

        it 'no relationship is created' do
          expect { subject }.not_to change { EpicIssue.count }
        end

        it 'does not create notes' do
          expect { subject }.not_to change { Note.count }
        end

        it 'returns an error' do
          expect(subject).to eq(message: 'Issue(s) already assigned', status: :error, http_status: 409)
        end

        context 'when at least one of the issues is still not assigned to the epic' do
          let_it_be(:valid_reference) { issue2.to_reference(full: true) }

          subject { assign_issue([valid_reference, issue.to_reference(full: true)]) }

          include_examples 'returns success'
        end
      end

      context 'when an issue is already assigned to another epic', :sidekiq_inline do
        before do
          group.add_guest(user)
          project.add_guest(user)
          create(:epic_issue, epic: epic, issue: issue)
          issue.reload
        end

        let_it_be(:another_epic) { create(:epic, group: group) }

        subject do
          params = { issuable_references: [valid_reference] }

          described_class.new(another_epic, user, params).execute
        end

        it 'does not create a new association' do
          expect { subject }.not_to change(EpicIssue, :count)
        end

        it 'updates the existing association' do
          expect { subject }.to change { EpicIssue.last.epic }.from(epic).to(another_epic)
        end

        it 'returns success status and created links', :aggregate_failures do
          expect(subject.keys).to match_array([:status, :created_references])
          expect(subject[:status]).to eq(:success)
          expect(subject[:created_references].count).to eq(1)
        end

        it 'creates 3 system notes', :sidekiq_inline do
          expect { subject }.to change { Note.count }.by(3)
        end

        it 'updates both old and new epic milestone dates' do
          expect(Epics::UpdateDatesService).to receive(:new).with([another_epic, issue.epic]).and_call_original
          allow(EpicIssue).to receive(:find_or_initialize_by).with(issue: issue).and_wrap_original { |m, *args|
            existing_epic_issue = m.call(*args)
            existing_epic_issue
          }

          subject
        end

        it 'creates a note correctly for the original epic' do
          subject

          note = Note.find_by(system: true, noteable_type: 'Epic', noteable_id: epic.id)

          expect(note.note).to eq("moved issue #{issue.to_reference(epic.group)} to epic #{another_epic.to_reference(epic.group)}")
          expect(note.system_note_metadata.action).to eq('epic_issue_moved')
        end

        it 'creates a note correctly for the new epic' do
          subject

          note = Note.find_by(system: true, noteable_type: 'Epic', noteable_id: another_epic.id)

          expect(note.note).to eq("added issue #{issue.to_reference(epic.group)} from epic #{epic.to_reference(epic.group)}")
          expect(note.system_note_metadata.action).to eq('epic_issue_moved')
        end

        it 'creates a note correctly for the issue' do
          subject

          note = Note.find_by(system: true, noteable_type: 'Issue', noteable_id: issue.id)

          expect(note.note).to eq("changed epic to #{another_epic.to_reference(issue.project)}")
          expect(note.system_note_metadata.action).to eq('issue_changed_epic')
        end
      end

      context 'when issue from non group project is given' do
        subject { assign_issue([another_issue.to_reference(full: true)]) }

        let_it_be(:another_issue) { create :issue }

        before do
          group.add_guest(user)
          another_issue.project.add_guest(user)
        end

        include_examples 'returns an error'
      end
    end
  end
end
