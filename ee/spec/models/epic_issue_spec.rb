# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicIssue, feature_category: :portfolio_management do
  let_it_be(:ancestor) { create(:group) }
  let_it_be(:group) { create(:group, parent: ancestor) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }

  describe 'validations' do
    let(:epic) { build(:epic, group: group) }
    let(:confidential_epic) { build(:epic, :confidential, group: group) }
    let(:issue) { build(:issue, project: project) }
    let(:confidential_issue) { build(:issue, :confidential, project: project) }

    it 'is valid to add non-confidential issue to non-confidential epic' do
      expect(build(:epic_issue, epic: epic, issue: issue)).to be_valid
    end

    it 'is valid to add confidential issue to confidential epic' do
      expect(build(:epic_issue, epic: confidential_epic, issue: confidential_issue)).to be_valid
    end

    it 'is valid to add confidential issue to non-confidential epic' do
      expect(build(:epic_issue, epic: epic, issue: confidential_issue)).to be_valid
    end

    it 'is not valid to add non-confidential issue to confidential epic' do
      expect(build(:epic_issue, epic: confidential_epic, issue: issue)).not_to be_valid
    end

    context 'group hierarchy' do
      let(:issue) { build(:issue, project: project) }

      subject { described_class.new(epic: epic, issue: issue) }

      context 'when epic and issue are from different group hierarchies' do
        let_it_be(:issue) { create(:issue) }

        it 'is valid' do
          expect(subject).to be_valid
        end
      end

      context 'when epic and issue belong to the same group' do
        it { is_expected.to be_valid }
      end

      context 'when epic is in an ancestor group' do
        let_it_be_with_refind(:project) { create(:project, group: create(:group, parent: group)) }

        it { is_expected.to be_valid }
      end

      context 'when epic is in a descendant group' do
        let_it_be(:project) { create(:project, group: ancestor) }

        it { is_expected.to be_valid }
      end
    end
  end

  context "relative positioning" do
    it_behaves_like "a class that supports relative positioning" do
      let(:factory) { :epic_tree_node }
      let(:default_params) { { parent: epic, group: epic.group } }

      def as_item(item)
        item.epic_tree_node_identity
      end
    end

    context 'with a mixed tree level' do
      let_it_be_with_reload(:left) { create(:epic_issue, epic: epic, issue: issue, relative_position: 100) }
      let_it_be_with_reload(:middle) { create(:epic, group: group, parent: epic, relative_position: 101) }
      let_it_be_with_reload(:right) { create(:epic_issue, epic: epic, relative_position: 102) }

      it 'can create space to the right' do
        RelativePositioning.mover.context(left).create_space_right
        [left, middle, right].each(&:reset)

        expect(middle.relative_position - left.relative_position).to be > 1
        expect(left.relative_position).to be < middle.relative_position
        expect(middle.relative_position).to be < right.relative_position
      end

      it 'can create space to the left' do
        RelativePositioning.mover.context(right).create_space_left
        [left, middle, right].each(&:reset)

        expect(right.relative_position - middle.relative_position).to be > 1
        expect(left.relative_position).to be < middle.relative_position
        expect(middle.relative_position).to be < right.relative_position
      end

      it 'moves nulls to the end' do
        leaves = create_list(:epic_issue, 2, epic: epic, relative_position: nil)
        nested = create(:epic, group: epic.group, parent: epic, relative_position: nil)
        moved = [*leaves, nested]
        level = [nested, *leaves, right]

        expect do
          EpicIssue.move_nulls_to_end(level)
        end.not_to change { right.reset.relative_position }

        moved.each(&:reset)

        expect(moved.map(&:relative_position)).to all(be > right.relative_position)
      end
    end
  end

  describe '#update_cached_metadata' do
    it 'schedules cache update for epic when new issue is added' do
      expect(::Epics::UpdateCachedMetadataWorker).to receive(:perform_async).with([epic.id]).once

      create(:epic_issue, epic: epic, issue: issue)
    end

    context 'when epic issue already exists' do
      let_it_be_with_reload(:epic_issue) { create(:epic_issue, epic: epic, issue: issue) }

      it 'schedules cache update for epic when epic issue is updated' do
        new_epic = create(:epic, group: group)

        expect(::Epics::UpdateCachedMetadataWorker).to receive(:perform_async).with([epic.id]).once
        expect(::Epics::UpdateCachedMetadataWorker).to receive(:perform_async).with([new_epic.id]).once

        epic_issue.update!(epic: new_epic)
      end

      it 'schedules cache update for epic when epic issue is destroyed' do
        expect(::Epics::UpdateCachedMetadataWorker).to receive(:perform_async).with([epic.id]).once

        epic_issue.destroy!
      end
    end
  end

  describe '#exportable_record?' do
    let_it_be(:user) { create(:user) }
    let_it_be(:private_group) { create(:group, :private) }
    let_it_be(:private_epic) { create(:epic, group: private_group) }
    let_it_be(:epic_issue) { create(:epic_issue, epic: private_epic, issue: issue) }

    subject { epic_issue.exportable_record?(current_user) }

    before do
      stub_licensed_features(epics: true)
    end

    context 'when user is nil' do
      let(:current_user) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when user cannot read epic' do
      let(:current_user) { user }

      it { is_expected.to be_falsey }
    end

    context 'when user can read epic' do
      let(:current_user) { user }

      before do
        private_group.add_reporter(user)
      end

      it { is_expected.to be_truthy }
    end
  end
end
