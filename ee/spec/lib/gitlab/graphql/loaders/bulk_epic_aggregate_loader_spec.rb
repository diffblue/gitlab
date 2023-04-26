# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Loaders::BulkEpicAggregateLoader do
  include_context 'includes EpicAggregate constants'

  let_it_be(:ancestor) { create(:group, :public) }
  let_it_be(:group) { create(:group, :public, parent: ancestor) }
  let_it_be(:subgroup) { create(:group, :private, parent: group) }

  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:subproject) { create(:project, namespace: subgroup) }

  let_it_be(:parent_epic) { create(:epic, group: ancestor, title: 'parent epic') }
  let_it_be(:epic_with_issues) { create(:epic, group: group, parent: parent_epic, state: :opened, title: 'epic with issues') }

  # closed, no issues
  let_it_be(:epic_without_issues) { create(:epic, group: group, parent: parent_epic, state: :closed, title: 'epic without issues') }

  # open, public
  let_it_be(:issue1) { create(:issue, project: project, weight: 1, state: :opened) }
  let_it_be(:issue2) { create(:issue, project: project, weight: 1, state: :opened) }
  # closed
  let_it_be(:issue3) { create(:issue, project: project, weight: 1, state: :closed) }
  let_it_be(:issue4) { create(:issue, project: project, weight: 1, state: :closed) }
  # confidential
  let_it_be(:issue5) { create(:issue, project: project, weight: 1, confidential: true, state: :opened) }
  let_it_be(:issue6) { create(:issue, project: project, weight: 1, confidential: true, state: :opened) }
  # in private project, private subgroup
  let_it_be(:issue7) { create(:issue, project: subproject, weight: 1, state: :opened) }
  let_it_be(:issue8) { create(:issue, project: subproject, weight: 1, state: :opened) }
  # private project, confidential, private subgroup
  let_it_be(:issue9) { create(:issue, project: subproject, weight: 1, confidential: true, state: :opened) }
  let_it_be(:issue10) { create(:issue, project: subproject, weight: 1, confidential: true, state: :opened) }
  # nil weight doesn't break it
  let_it_be(:issue11) { create(:issue, project: project, weight: 0, state: :opened) }
  let_it_be(:issue12) { create(:issue, project: project, weight: nil, state: :opened) }

  let_it_be(:epic_issue1) { create(:epic_issue, epic: parent_epic, issue: issue1) }
  let_it_be(:epic_issue2) { create(:epic_issue, epic: epic_with_issues, issue: issue2) }
  let_it_be(:epic_issue3) { create(:epic_issue, epic: parent_epic, issue: issue3) }
  let_it_be(:epic_issue4) { create(:epic_issue, epic: epic_with_issues, issue: issue4) }
  let_it_be(:epic_issue5) { create(:epic_issue, epic: parent_epic, issue: issue5) }
  let_it_be(:epic_issue6) { create(:epic_issue, epic: epic_with_issues, issue: issue6) }
  let_it_be(:epic_issue7) { create(:epic_issue, epic: parent_epic, issue: issue7) }
  let_it_be(:epic_issue8) { create(:epic_issue, epic: epic_with_issues, issue: issue8) }
  let_it_be(:epic_issue9) { create(:epic_issue, epic: parent_epic, issue: issue9) }
  let_it_be(:epic_issue10) { create(:epic_issue, epic: epic_with_issues, issue: issue10) }
  let_it_be(:epic_issue11) { create(:epic_issue, epic: parent_epic, issue: issue11) }
  let_it_be(:epic_issue12) { create(:epic_issue, epic: epic_with_issues, issue: issue12) }

  subject { described_class.new(epic_ids: target_ids) }

  before do
    stub_licensed_features(epics: true)
  end

  context 'when epic ids with issues is provided' do
    let(:target_ids) { parent_epic.id }

    it 'sums all the weights, even confidential, or in private groups' do
      expected_result = {
        parent_epic.id => [
          result_for(parent_epic, issues_state: OPENED_ISSUE_STATE, issues_count: 5, issues_weight_sum: 4),
          result_for(parent_epic, issues_state: CLOSED_ISSUE_STATE, issues_count: 1, issues_weight_sum: 1)
        ],
        epic_with_issues.id => [
          result_for(epic_with_issues, issues_state: OPENED_ISSUE_STATE, issues_count: 5, issues_weight_sum: 4),
          result_for(epic_with_issues, issues_state: CLOSED_ISSUE_STATE, issues_count: 1, issues_weight_sum: 1)
        ],
        epic_without_issues.id => [
          result_for(epic_without_issues, issues_state: nil, issues_count: 0, issues_weight_sum: 0)
        ]
      }

      result = subject.execute

      expected_result.each do |epic_id, records|
        expect(result[epic_id]).to match_array records
      end
    end

    it 'contains results for all epics, even if they do not have issues' do
      result = subject.execute

      # epic_without_issues is included, even if it has none
      expect(result.keys).to match_array([parent_epic.id, epic_with_issues.id, epic_without_issues.id])
    end

    it 'loads epic issues metadata in batches' do
      stub_const("#{described_class}::EPIC_BATCH_SIZE", 1)
      allow(Epic).to receive(:issue_metadata_for_epics).and_return([])

      ids_batch_1 = [parent_epic.id]
      ids_batch_2 = [epic_with_issues.id]
      ids_batch_3 = [epic_without_issues.id]
      limit = described_class::MAXIMUM_LOADABLE

      expect(::Epic).to receive(:issue_metadata_for_epics).with(epic_ids: ids_batch_1, limit: limit, count_health_status: false)
      expect(::Epic).to receive(:issue_metadata_for_epics).with(epic_ids: ids_batch_2, limit: limit, count_health_status: false)
      expect(::Epic).to receive(:issue_metadata_for_epics).with(epic_ids: ids_batch_3, limit: limit, count_health_status: false)

      subject.execute
    end

    it 'errors when the number of retrieved records exceeds the maximum' do
      stub_const("Gitlab::Graphql::Loaders::BulkEpicAggregateLoader::MAXIMUM_LOADABLE", 4)

      expect { subject.execute }.to raise_error(ArgumentError, /too many records/)
    end

    it 'errors when the number of retrieved epics exceeds the maximum' do
      stub_const("Gitlab::Graphql::Loaders::BulkEpicAggregateLoader::MAXIMUM_LOADABLE", 1)

      expect { subject.execute }.to raise_error(ArgumentError, /too many epics/)
    end

    context 'testing for a single database query' do
      it 'does not repeat database queries for subepics' do
        recorder = ActiveRecord::QueryRecorder.new { described_class.new(epic_ids: epic_with_issues.id).execute }

        # this one has sub-epics, but there should still only be one query
        expect { described_class.new(epic_ids: [parent_epic.id, epic_with_issues.id]).execute }.not_to exceed_query_limit(recorder)
      end

      it 'avoids N+1' do
        recorder = ActiveRecord::QueryRecorder.new { described_class.new(epic_ids: epic_with_issues.id).execute }

        expect { described_class.new(epic_ids: [epic_with_issues.id, parent_epic.id]).execute }.not_to exceed_query_limit(recorder)
      end
    end
  end

  context 'when an epic without issues is provided' do
    let(:target_ids) { epic_without_issues.id }

    it 'returns a placeholder' do
      expected_result = [
        result_for(epic_without_issues, issues_state: nil, issues_count: 0, issues_weight_sum: 0)
      ]

      actual_result = subject.execute

      expect(actual_result[epic_without_issues.id]).to match_array(expected_result)
    end
  end

  context 'when no epic ids are provided' do
    [nil, [], ""].each do |empty_arg|
      context "with #{empty_arg}" do
        let(:target_ids) { empty_arg }

        it 'returns an empty set' do
          expect(subject.execute).to eq({})
        end
      end
    end
  end

  def result_for(epic, issues_state:, issues_count:, issues_weight_sum:)
    {
      id: epic.id,
      iid: epic.iid,
      issues_count: issues_count,
      issues_weight_sum: issues_weight_sum,
      parent_id: epic.parent_id,
      issues_state_id: issues_state,
      epic_state_id: Epic.available_states[epic.state_id]
    }.stringify_keys
  end
end
