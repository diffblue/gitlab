# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNotes::EpicsService, feature_category: :portfolio_management do
  let_it_be(:group)   { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:author)  { create(:user) }

  let(:noteable)      { create(:issue, project: project) }
  let(:issue)         { noteable }
  let(:epic)          { create(:epic, group: group) }

  describe '#epic_issue' do
    let(:noteable) { epic }

    context 'issue added to an epic' do
      subject { described_class.new(noteable: noteable, author: author).epic_issue(issue, :added) }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'epic_issue_added' }
      end

      it 'creates the note text correctly' do
        expect(subject.note).to eq("added issue #{issue.to_reference(epic.group)}")
      end
    end

    context 'issue removed from an epic' do
      subject { described_class.new(noteable: epic, author: author).epic_issue(issue, :removed) }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'epic_issue_removed' }
      end

      it 'creates the note text correctly' do
        expect(subject.note).to eq("removed issue #{issue.to_reference(epic.group)}")
      end
    end
  end

  describe '#issue_on_epic' do
    context 'issue added to an epic' do
      subject { described_class.new(noteable: epic, author: author).issue_on_epic(issue, :added) }

      it_behaves_like 'a system note' do
        let(:action) { 'issue_added_to_epic' }
      end

      it 'creates the note text correctly' do
        expect(subject.note).to eq("added to epic #{epic.to_reference(issue.project)}")
      end
    end

    context 'issue removed from an epic' do
      subject { described_class.new(noteable: epic, author: author).issue_on_epic(issue, :removed) }

      it_behaves_like 'a system note' do
        let(:action) { 'issue_removed_from_epic' }
      end

      it 'creates the note text correctly' do
        expect(subject.note).to eq("removed from epic #{epic.to_reference(issue.project)}")
      end
    end

    context 'invalid type' do
      it 'raises an error' do
        expect { described_class.new(noteable: epic, author: author).issue_on_epic(issue, :invalid) }
          .not_to change { Note.count }
      end
    end
  end

  describe '#change_epic_date_note' do
    let(:timestamp) { Time.current }

    context 'when start date was changed' do
      let(:noteable) { create(:epic) }

      subject { described_class.new(noteable: noteable, author: author).change_epic_date_note('start date', timestamp) }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'epic_date_changed' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq "changed start date to #{timestamp.strftime('%b %-d, %Y')}"
      end
    end

    context 'when start date was removed' do
      let(:noteable) { create(:epic, start_date: timestamp) }

      subject { described_class.new(noteable: noteable, author: author).change_epic_date_note('start date', nil) }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'epic_date_changed' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq 'removed the start date'
      end
    end
  end

  describe '#issue_promoted' do
    context 'note on the epic' do
      subject { described_class.new(noteable: epic, author: author).issue_promoted(issue, direction: :from) }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'moved' }
        let(:expected_noteable) { epic }
      end

      it 'sets the note text' do
        expect(subject.note).to eq("promoted from issue #{issue.to_reference(group)}")
      end
    end

    context 'note on the issue' do
      subject { described_class.new(noteable: issue, author: author).issue_promoted(epic, direction: :to) }

      it_behaves_like 'a system note' do
        let(:action) { 'moved' }
      end

      it 'sets the note text' do
        expect(subject.note).to eq("promoted to epic #{epic.to_reference(project)}")
      end
    end
  end

  describe '#change_epics_relation' do
    context 'relate epic' do
      let(:child_epic) { create(:epic, parent: epic, group: group) }
      let(:noteable) { child_epic }

      subject { described_class.new(noteable: epic, author: author).change_epics_relation(child_epic, 'relate_epic') }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'relate_epic' }
      end

      context 'when epic is added as child to a parent epic' do
        it 'sets the note text' do
          expect { subject }.to change { Note.system.count }.from(0).to(2)
          expect(Note.first.note).to eq("added epic &#{child_epic.iid} as child epic")
          expect(Note.last.note).to eq("added epic &#{epic.iid} as parent epic")
        end
      end

      context 'when added epic is from a subgroup' do
        let(:subgroup) { create(:group, parent: group) }

        before do
          child_epic.update!({ group: subgroup })
        end

        it 'sets the note text' do
          expect { subject }.to change { Note.system.count }.from(0).to(2)
          expect(Note.first.note).to eq("added epic #{group.path}/#{subgroup.path}&#{child_epic.iid} as child epic")
          expect(Note.last.note).to eq("added epic #{group.path}&#{epic.iid} as parent epic")
        end
      end
    end

    context 'unrelate epic' do
      let(:child_epic) { create(:epic, parent: epic, group: group) }
      let(:noteable) { child_epic }

      subject { described_class.new(noteable: epic, author: author).change_epics_relation(child_epic, 'unrelate_epic') }

      it_behaves_like 'a system note', exclude_project: true do
        let(:action) { 'unrelate_epic' }
      end

      context 'when child epic is removed from a parent epic' do
        it 'sets the note text' do
          expect { subject }.to change { Note.system.count }.from(0).to(2)
          expect(Note.first.note).to eq("removed child epic &#{child_epic.iid}")
          expect(Note.last.note).to eq("removed parent epic &#{epic.iid}")
        end
      end

      context 'when removed epic is from a subgroup' do
        let(:subgroup) { create(:group, parent: group) }

        before do
          child_epic.update!({ group: subgroup })
        end

        it 'sets the note text' do
          expect { subject }.to change { Note.system.count }.from(0).to(2)
          expect(Note.first.note).to eq("removed child epic #{group.path}/#{subgroup.path}&#{child_epic.iid}")
          expect(Note.last.note).to eq("removed parent epic #{group.path}&#{epic.iid}")
        end
      end
    end
  end

  describe '#move_child_epic_to_new_parent' do
    let(:noteable) { previous_parent_epic }

    let_it_be(:new_parent_epic) { create(:epic, group: group) }
    let_it_be(:previous_parent_epic) { create(:epic, group: group) }
    let_it_be(:child_epic) { create(:epic, parent: new_parent_epic, group: group) }

    subject(:move_child_epic_to_new_parent) do
      described_class.new(noteable: previous_parent_epic, author: author)
        .move_child_epic_to_new_parent(child_epic, new_parent_epic)
    end

    it_behaves_like 'a system note', exclude_project: true do
      let(:action) { 'moved' }
    end

    it 'sets the note text' do
      expect { move_child_epic_to_new_parent }.to change { Note.system.count }.by(1)

      expect(Note.last.note).to eq("moved child epic &#{child_epic.iid} to epic &#{new_parent_epic.iid}")
    end

    context "when child epic's new parent is in a subgroup" do
      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:child_epic) { create(:epic, parent: new_parent_epic, group: subgroup) }

      it 'sets the note text' do
        expect { move_child_epic_to_new_parent }.to change { Note.system.count }.by(1)

        child_epic_path = "#{group.path}/#{subgroup.path}&#{child_epic.iid}"
        parent_epic_path = "#{group.path}&#{new_parent_epic.iid}"

        expect(Note.last.note).to eq("moved child epic #{child_epic_path} to epic #{parent_epic_path}")
      end
    end
  end
end
