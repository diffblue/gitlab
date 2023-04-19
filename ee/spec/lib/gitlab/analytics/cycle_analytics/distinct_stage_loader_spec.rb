# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::DistinctStageLoader, feature_category: :value_stream_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:stage_1) { create(:cycle_analytics_stage, namespace: group, start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_closed) }
  let_it_be(:common_stage_params) { { start_event_identifier: :issue_created, end_event_identifier: :issue_first_associated_with_milestone } }
  let_it_be(:stage_2) { create(:cycle_analytics_stage, namespace: group, **common_stage_params) }
  let_it_be(:stage_duplicate) { create(:cycle_analytics_stage, namespace: group, **common_stage_params) }
  let_it_be(:stage_triplicate) { create(:cycle_analytics_stage, namespace: group, **common_stage_params) }

  let(:lead_time_name) { 'lead time' }
  let(:cycle_time_name) { 'cycle time' }
  let(:time_to_merge_name) { 'time to merge' }

  let(:in_memory_stages_names) { [lead_time_name, cycle_time_name, time_to_merge_name] }
  let(:in_memory_stages_count) { in_memory_stages_names.count }

  subject(:distinct_stages) { described_class.new(group: group).stages }

  it 'returns the distinct stages by stage_event_hash_id' do
    distinct_stage_hash_ids = subject.map(&:stage_event_hash_id)

    expect(distinct_stage_hash_ids).to eq(distinct_stage_hash_ids.uniq)
  end

  context 'when in-memory stages are not defined as stages', :aggregate_failures do
    it 'creates three stage event hash records' do
      expect { distinct_stages }.to change { Analytics::CycleAnalytics::StageEventHash.count }.by(3)
    end
  end

  context 'when all in-memory stages have been defined' do
    let(:lead_time) { distinct_stages.find { |stage| stage.name == lead_time_name } }
    let(:cycle_time) { distinct_stages.find { |stage| stage.name == cycle_time_name } }
    let(:time_to_merge) { distinct_stages.find { |stage| stage.name == time_to_merge_name } }
    let(:in_memory_stages) { [lead_time, cycle_time, time_to_merge] }

    it 'returns in-memory stages' do
      # all should be present
      expect(in_memory_stages.compact.count).to eq in_memory_stages_count

      # all should have unique stage event hash IDs
      expect(in_memory_stages.map(&:stage_event_hash_id).count).to eq in_memory_stages_count
    end

    it 'has distinct values for all in-memory stages' do
      expect(in_memory_stages.map(&:stage_event_hash_id).uniq.count).to eq in_memory_stages_count
    end

    it 'returns total number of stages - in-memory + persisted' do
      expect(distinct_stages.size).to eq(in_memory_stages_count + 2)
    end
  end

  context 'when a subset of in-memory stages are already defined' do
    let_it_be(:cycle_time) do
      create(:cycle_analytics_stage,
             namespace: group,
             start_event_identifier: Gitlab::Analytics::CycleAnalytics::Summary::LeadTime.start_event_identifier,
             end_event_identifier: Gitlab::Analytics::CycleAnalytics::Summary::LeadTime.end_event_identifier)
    end

    let_it_be(:lead_time) do
      create(:cycle_analytics_stage,
             namespace: group,
             start_event_identifier: Gitlab::Analytics::CycleAnalytics::Summary::CycleTime.start_event_identifier,
             end_event_identifier: Gitlab::Analytics::CycleAnalytics::Summary::CycleTime.end_event_identifier)
    end

    it 'does not create extra stage event hash records' do
      # only creates time_to_merge because that hasn't been defined yet
      expect { distinct_stages }.to change { Analytics::CycleAnalytics::StageEventHash.count }.by(1)
    end
  end
end
