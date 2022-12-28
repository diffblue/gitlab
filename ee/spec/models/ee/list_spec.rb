# frozen_string_literal: true

require 'spec_helper'

RSpec.describe List do
  let(:board) { create(:board) }

  describe 'relationships' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:milestone) }
    it { is_expected.to belong_to(:iteration) }
  end

  describe 'validations' do
    it { is_expected.to validate_numericality_of(:max_issue_count).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_numericality_of(:max_issue_weight).only_integer.is_greater_than_or_equal_to(0) }
    it { is_expected.to validate_inclusion_of(:limit_metric).in_array(EE::List::LIMIT_METRIC_TYPES).allow_nil }
  end

  context 'when it is an assignee type' do
    subject { described_class.new(list_type: :assignee, board: board) }

    it { is_expected.to be_destroyable }
    it { is_expected.to be_movable }

    describe 'validations' do
      it { is_expected.to validate_presence_of(:user) }
    end

    describe '#title' do
      it 'returns the username as title' do
        subject.user = create(:user, username: 'some_user')

        expect(subject.title).to eq('@some_user')
      end
    end
  end

  context 'when it is a milestone type' do
    let(:milestone) { build(:milestone, title: 'awesome-release') }

    subject { described_class.new(list_type: :milestone, milestone: milestone, board: board) }

    it { is_expected.to be_destroyable }
    it { is_expected.to be_movable }

    describe 'validations' do
      it { is_expected.to validate_presence_of(:milestone) }

      it 'is invalid when feature is not available' do
        stub_licensed_features(board_milestone_lists: false)

        expect(subject).to be_invalid
        expect(subject.errors[:list_type])
          .to contain_exactly('Milestone lists not available with your current license')
      end
    end

    describe '#title' do
      it 'returns the milestone title' do
        expect(subject.title).to eq('awesome-release')
      end
    end
  end

  context 'when it is an iteration type' do
    let(:iteration) { build(:iteration, group: create(:group)) }

    subject { described_class.new(list_type: :iteration, iteration: iteration, board: board) }

    it { is_expected.to be_destroyable }
    it { is_expected.to be_movable }

    describe 'validations' do
      it { is_expected.to validate_presence_of(:iteration) }

      it 'is invalid when feature is not available' do
        stub_licensed_features(board_iteration_lists: false)

        expect(subject).to be_invalid
        expect(subject.errors[:list_type])
          .to contain_exactly('Iteration lists not available with your current license')
      end
    end

    describe '#title' do
      it 'returns the iteration cadence and period as title' do
        expect(subject.title).to eq(iteration.display_text)
      end
    end
  end

  describe '#wip_limits_available?' do
    let!(:project) { create(:project) }
    let!(:group) { create(:group) }

    let!(:board1) { create(:board, resource_parent: project, name: 'b') }
    let!(:board2) { create(:board, resource_parent: group, name: 'a') }

    let!(:list1) { create(:list, board: board1) }
    let!(:list2) { create(:list, board: board2) }

    context 'with enabled wip_limits' do
      before do
        stub_licensed_features(wip_limits: true)
      end

      it 'returns the expected values' do
        expect(list1.wip_limits_available?).to be_truthy
        expect(list2.wip_limits_available?).to be_truthy
      end
    end

    context 'with disabled wip_limits' do
      before do
        stub_licensed_features(wip_limits: false)
      end

      it 'returns the expected values' do
        expect(list1.wip_limits_available?).to be_falsy
        expect(list2.wip_limits_available?).to be_falsy
      end
    end
  end
end
