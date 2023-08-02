# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::ValueStreamDashboard::TopLevelGroupCounterService, feature_category: :value_stream_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:subsubgroup) { create(:group, parent: subgroup) }

  let_it_be(:project_in_group) { create(:project, group: group) }
  let_it_be(:project_in_subgroup) { create(:project, group: subgroup) }
  let_it_be(:another_project_in_subgroup) { create(:project, group: subgroup) }
  let_it_be(:project_in_subsubgroup) { create(:project, group: subsubgroup) }

  let_it_be(:issue_in_group) { create(:issue, project: project_in_group) }
  let_it_be(:another_issue_in_group) { create(:issue, project: project_in_group) }
  let_it_be(:issue_in_subsubgroup) { create(:issue, project: project_in_subsubgroup) }

  let_it_be(:mr_in_subsubgroup1) { create(:merge_request, :unique_branches, source_project: project_in_subsubgroup) }
  let_it_be(:mr_in_subsubgroup2) { create(:merge_request, :unique_branches, source_project: project_in_subsubgroup) }

  let_it_be(:ci_pipeline1) { create(:ci_pipeline, project: project_in_group) }
  let_it_be(:ci_pipeline2) { create(:ci_pipeline, project: project_in_group) }
  let_it_be(:ci_pipeline3) { create(:ci_pipeline, project: project_in_group) }

  let_it_be(:aggregation) { create(:value_stream_dashboard_aggregation, namespace: group, last_run_at: nil) }

  let(:raw_cursor) { { top_level_namespace_id: aggregation.id } }
  let(:cursor) { described_class.load_cursor(raw_cursor: raw_cursor) }
  let(:runtime_limiter) { Analytics::CycleAnalytics::RuntimeLimiter.new }
  let(:group_namespace_ids) { group.self_and_descendant_ids.pluck(:id) }
  let(:project_namespace_ids) { group.all_projects.pluck(:project_namespace_id) }

  let(:run_service) do
    described_class
      .new(aggregation: aggregation, cursor: cursor, runtime_limiter: runtime_limiter)
      .execute
  end

  let(:expected_counts) do
    [
      { metric: 'projects', namespace_id: group.id, count: 1 },
      { metric: 'projects', namespace_id: subgroup.id, count: 2 },
      { metric: 'projects', namespace_id: subsubgroup.id, count: 1 },
      { metric: 'issues', namespace_id: project_in_group.project_namespace.id, count: 2 },
      { metric: 'issues', namespace_id: project_in_subgroup.project_namespace.id, count: 0 },
      { metric: 'issues', namespace_id: another_project_in_subgroup.project_namespace.id, count: 0 },
      { metric: 'issues', namespace_id: project_in_subsubgroup.project_namespace.id, count: 1 },
      { metric: 'groups', namespace_id: group.id, count: 1 },
      { metric: 'groups', namespace_id: subgroup.id, count: 1 },
      { metric: 'groups', namespace_id: subsubgroup.id, count: 0 },
      { metric: 'merge_requests', namespace_id: project_in_group.project_namespace.id, count: 0 },
      { metric: 'merge_requests', namespace_id: project_in_subgroup.project_namespace.id, count: 0 },
      { metric: 'merge_requests', namespace_id: another_project_in_subgroup.project_namespace.id, count: 0 },
      { metric: 'merge_requests', namespace_id: project_in_subsubgroup.project_namespace.id, count: 2 },
      { metric: 'pipelines', namespace_id: project_in_group.project_namespace.id, count: 3 },
      { metric: 'pipelines', namespace_id: project_in_subgroup.project_namespace.id, count: 0 },
      { metric: 'pipelines', namespace_id: another_project_in_subgroup.project_namespace.id, count: 0 },
      { metric: 'pipelines', namespace_id: project_in_subsubgroup.project_namespace.id, count: 0 }
    ]
  end

  subject(:persisted_counts) do
    Analytics::ValueStreamDashboard::Count
      .where(namespace_id: group_namespace_ids + project_namespace_ids)
      .order(:namespace_id)
  end

  it 'returns successful response' do
    service_response = run_service

    expect(service_response).to be_success

    expect(service_response.payload[:result]).to eq(:finished)
    expect(aggregation.reload.last_run_at).not_to be_nil
  end

  it 'stores aggregated counts' do
    run_service

    expect(persisted_counts).to match_array(expected_counts.map { |a| have_attributes(a) })
  end

  context 'when iterating by one record at the time' do
    it 'stores aggregated counts' do
      stub_const("#{described_class}::COUNT_BATCH_SIZE", 1)
      stub_const("#{Gitlab::Analytics::ValueStreamDashboard::NamespaceCursor}::NAMESPACE_BATCH_SIZE", 1)

      run_service

      expect(persisted_counts).to match_array(expected_counts.map { |a| have_attributes(a) })
    end
  end

  context 'when restoring the metric from the cursor' do
    let(:raw_cursor) do
      {
        top_level_namespace_id: aggregation.id,
        namespace_id: project_in_group.project_namespace_id,
        last_count: 1,
        metric: Analytics::ValueStreamDashboard::Count.metrics[:issues],
        last_value: issue_in_group.iid
      }
    end

    let(:expected_counts) do
      [
        { metric: 'issues', namespace_id: project_in_group.project_namespace.id, count: 2 },
        { metric: 'issues', namespace_id: project_in_subgroup.project_namespace.id, count: 0 },
        { metric: 'issues', namespace_id: another_project_in_subgroup.project_namespace.id, count: 0 },
        { metric: 'issues', namespace_id: project_in_subsubgroup.project_namespace.id, count: 1 }
      ]
    end

    it 'continues the processing from the cursor' do
      run_service

      issues_only = persisted_counts.select(&:issues?)
      expect(issues_only).to match(expected_counts.map { |a| have_attributes(a) })
    end
  end

  context 'when counting is interrupted during iteration' do
    let(:raw_cursor) do
      {
        top_level_namespace_id: aggregation.id,
        namespace_id: project_in_group.project_namespace_id,
        last_count: 1,
        metric: Analytics::ValueStreamDashboard::Count.metrics[:issues],
        last_value: issue_in_group.iid
      }
    end

    it 'returns the cursor without modification' do
      stub_const("#{described_class}::COUNT_BATCH_SIZE", 1)

      original_cursor = raw_cursor.clone
      allow(runtime_limiter).to receive(:over_time?).and_return(true)
      allow(runtime_limiter).to receive(:was_over_time?).and_return(true)

      service_response = run_service

      expect(service_response.payload[:result]).to eq(:interrupted)
      expect(service_response.payload[:cursor].dump).to eq(original_cursor)
    end

    it 'does not update the last_run_at' do
      allow(runtime_limiter).to receive(:over_time?).and_return(true)
      allow(runtime_limiter).to receive(:was_over_time?).and_return(true)

      expect { run_service }.not_to change { aggregation.reload.last_run_at }
    end
  end

  context 'when counting is interrupted during batch counting' do
    let(:raw_cursor) { { top_level_namespace_id: aggregation.id } }

    it 'returns the cursor with the latest state' do
      stub_const("#{described_class}::COUNT_BATCH_SIZE", 1)

      allow(runtime_limiter).to receive(:over_time?).and_return(false, true)
      allow(runtime_limiter).to receive(:was_over_time?).and_return(true)

      service_response = run_service

      expect(service_response.payload[:result]).to eq(:interrupted)
      expect(service_response.payload[:cursor].dump).to match(a_hash_including(
        metric: 1,
        namespace_id: group.id,
        last_value: project_in_group.id,
        last_count: 1
      ))
    end
  end
end
