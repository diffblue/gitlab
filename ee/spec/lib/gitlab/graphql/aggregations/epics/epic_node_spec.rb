# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Aggregations::Epics::EpicNode do
  include_context 'includes EpicAggregate constants'

  let(:epic_id) { 34 }
  let(:epic_iid) { 5 }

  describe '#initialize' do
    let(:fake_data) do
      [
        { iid: epic_iid, epic_state_id: epic_state_id, issues_count: 1, issues_weight_sum: 2, parent_id: parent_id, issues_state_id: OPENED_ISSUE_STATE },
        { iid: epic_iid, epic_state_id: epic_state_id, issues_count: 2, issues_weight_sum: 2, parent_id: parent_id, issues_state_id: CLOSED_ISSUE_STATE }
      ]
    end

    shared_examples 'setting attributes based on the first record' do |attributes|
      let(:parent_id) { attributes[:parent_id] }
      let(:epic_state_id) { attributes[:epic_state_id] }

      it 'sets epic attributes based on the first record' do
        new_node = described_class.new(epic_id, fake_data)

        expect(new_node.parent_id).to eq parent_id
        expect(new_node.epic_state_id).to eq epic_state_id
      end
    end

    it_behaves_like 'setting attributes based on the first record', { epic_state_id: Gitlab::Graphql::Aggregations::Epics::Constants::OPENED_EPIC_STATE, parent_id: nil }
    it_behaves_like 'setting attributes based on the first record', { epic_state_id: Gitlab::Graphql::Aggregations::Epics::Constants::CLOSED_EPIC_STATE, parent_id: 2 }
  end

  describe 'recursive totals' do
    subject { described_class.new(epic_id, [{ parent_id: nil, epic_state_id: CLOSED_EPIC_STATE }]) }

    before do
      allow(subject).to receive(:epic_info_flat_list).and_return(flat_info)
    end

    shared_examples 'has_issues?' do |expected_result|
      it "returns #{expected_result}" do
        expect(subject.has_issues?).to eq expected_result
      end
    end

    context 'an epic with no child epics' do
      context 'with no child issues', :aggregate_failures do
        let(:flat_info) { [] }

        it 'has the correct aggregates', :aggregate_failures do
          expect(subject).to have_aggregate(ISSUE_TYPE, COUNT, OPENED_ISSUE_STATE, 0)
          expect(subject).to have_aggregate(ISSUE_TYPE, COUNT, CLOSED_ISSUE_STATE, 0)
          expect(subject).to have_aggregate(ISSUE_TYPE, WEIGHT_SUM, OPENED_ISSUE_STATE, 0)
          expect(subject).to have_aggregate(ISSUE_TYPE, WEIGHT_SUM, CLOSED_ISSUE_STATE, 0)

          expect(subject).to have_aggregate(EPIC_TYPE, COUNT, OPENED_EPIC_STATE, 0)
          expect(subject).to have_aggregate(EPIC_TYPE, COUNT, CLOSED_EPIC_STATE, 0)
        end

        it_behaves_like 'has_issues?', false
      end

      context 'with an issue with 0 weight', :aggregate_failures do
        let(:flat_info) do
          [
            record_for(epic_id: epic_id, parent_id: nil, epic_state_id: CLOSED_EPIC_STATE, issues_state_id: OPENED_ISSUE_STATE, issues_count: 1, issues_weight_sum: 0)
          ]
        end

        it 'has the correct aggregates', :aggregate_failures do
          expect(subject).to have_aggregate(ISSUE_TYPE, COUNT, OPENED_ISSUE_STATE, 1)
          expect(subject).to have_aggregate(ISSUE_TYPE, COUNT, CLOSED_ISSUE_STATE, 0)
          expect(subject).to have_aggregate(ISSUE_TYPE, WEIGHT_SUM, OPENED_ISSUE_STATE, 0)
          expect(subject).to have_aggregate(ISSUE_TYPE, WEIGHT_SUM, CLOSED_ISSUE_STATE, 0)

          expect(subject).to have_aggregate(EPIC_TYPE, COUNT, OPENED_EPIC_STATE, 0)
          expect(subject).to have_aggregate(EPIC_TYPE, COUNT, CLOSED_EPIC_STATE, 0)
        end

        it_behaves_like 'has_issues?', true
      end

      context 'with an open issue with nonzero weight' do
        let(:flat_info) do
          [
            record_for(epic_id: epic_id, parent_id: nil, epic_state_id: CLOSED_EPIC_STATE, issues_state_id: OPENED_ISSUE_STATE, issues_count: 1, issues_weight_sum: 2)
          ]
        end

        it 'has the correct aggregates', :aggregate_failures do
          expect(subject).to have_aggregate(ISSUE_TYPE, COUNT, OPENED_ISSUE_STATE, 1)
          expect(subject).to have_aggregate(ISSUE_TYPE, COUNT, CLOSED_ISSUE_STATE, 0)
          expect(subject).to have_aggregate(ISSUE_TYPE, WEIGHT_SUM, OPENED_ISSUE_STATE, 2)
          expect(subject).to have_aggregate(ISSUE_TYPE, WEIGHT_SUM, CLOSED_ISSUE_STATE, 0)

          expect(subject).to have_aggregate(EPIC_TYPE, COUNT, OPENED_EPIC_STATE, 0)
          expect(subject).to have_aggregate(EPIC_TYPE, COUNT, CLOSED_EPIC_STATE, 0)
        end

        it_behaves_like 'has_issues?', true
      end

      context 'with a closed issue with nonzero weight' do
        let(:flat_info) do
          [
            record_for(epic_id: epic_id, parent_id: nil, epic_state_id: CLOSED_EPIC_STATE, issues_state_id: CLOSED_ISSUE_STATE, issues_count: 1, issues_weight_sum: 2)
          ]
        end

        it_behaves_like 'has_issues?', true
      end
    end

    context 'an epic with child epics' do
      let(:child_epic_id) { 45 }
      let(:child_epic_node) { described_class.new(child_epic_id, child_flat_info) }
      let(:flat_info) do
        [
          record_for(epic_id: epic_id, parent_id: nil, epic_state_id: OPENED_EPIC_STATE, issues_state_id: OPENED_ISSUE_STATE, issues_count: 0, issues_weight_sum: 0)
        ]
      end

      before do
        subject.children << child_epic_node
      end

      context 'with a child that has issues of nonzero weight' do
        let(:child_flat_info) do
          [
            record_for(epic_id: epic_id, parent_id: nil, epic_state_id: OPENED_EPIC_STATE, issues_state_id: OPENED_ISSUE_STATE, issues_count: 1, issues_weight_sum: 2)
          ]
        end

        it 'has the correct aggregates', :aggregate_failures do
          expect(subject).to have_aggregate(ISSUE_TYPE, COUNT, OPENED_ISSUE_STATE, 1)
          expect(subject).to have_aggregate(ISSUE_TYPE, COUNT, CLOSED_ISSUE_STATE, 0)
          expect(subject).to have_aggregate(ISSUE_TYPE, WEIGHT_SUM, OPENED_ISSUE_STATE, 2)
          expect(subject).to have_aggregate(ISSUE_TYPE, WEIGHT_SUM, CLOSED_ISSUE_STATE, 0)
          expect(subject).to have_aggregate(EPIC_TYPE, COUNT, OPENED_EPIC_STATE, 1)
          expect(subject).to have_aggregate(EPIC_TYPE, COUNT, CLOSED_EPIC_STATE, 0)
        end

        it_behaves_like 'has_issues?', false
      end
    end
  end

  def record_for(epic_id:, parent_id:, epic_state_id:, issues_state_id:, issues_count:, issues_weight_sum:)
    {
      epic_id: epic_id,
      issues_count: issues_count,
      issues_weight_sum: issues_weight_sum,
      parent_id: parent_id,
      issues_state_id: issues_state_id,
      epic_state_id: epic_state_id
    }
  end
end
