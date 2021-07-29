# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EpicIssue do
  describe 'validations' do
    let(:epic) { build(:epic) }
    let(:confidential_epic) { build(:epic, :confidential) }
    let(:issue) { build(:issue) }
    let(:confidential_issue) { build(:issue, :confidential) }

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
  end

  context "relative positioning" do
    it_behaves_like "a class that supports relative positioning" do
      let_it_be(:epic) { create(:epic) }
      let(:factory) { :epic_tree_node }
      let(:default_params) { { parent: epic, group: epic.group } }

      def as_item(item)
        item.epic_tree_node_identity
      end
    end

    context 'with a mixed tree level' do
      let_it_be(:epic) { create(:epic) }
      let_it_be_with_reload(:left) { create(:epic_issue, epic: epic, relative_position: 100) }
      let_it_be_with_reload(:middle) { create(:epic, group: epic.group, parent: epic, relative_position: 101) }
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

  describe '#epic_and_issue_at_same_group_hierarchy?' do
    let_it_be(:group) { create(:group) }
    let_it_be(:group_a) { create(:group, parent: group) }
    let_it_be(:group_b) { create(:group, parent: group) }
    let_it_be(:group_a_project_1) { create(:project, group: group) }

    let(:epic) { build(:epic, group: group_a) }

    subject { described_class.new(epic: epic, issue: issue).epic_and_issue_at_same_group_hierarchy? }

    context 'when epic and issue are at same group hierarchy' do
      let_it_be(:group_a_project_2) { create(:project, group: group_a) }

      let(:issue) { build(:issue, project: group_a_project_2) }

      it { is_expected.to eq(true) }
    end

    context 'when epic and issue are at different group hierarchies' do
      let_it_be(:group_b_project_1) { create(:project, group: group_b) }

      let(:issue) { build(:issue, project: group_b_project_1) }

      it { is_expected.to eq(false) }
    end
  end
end
