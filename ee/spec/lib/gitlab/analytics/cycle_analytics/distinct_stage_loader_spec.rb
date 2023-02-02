# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::DistinctStageLoader do
  let_it_be(:group) { create(:group) }
  let_it_be(:stage_1) { create(:cycle_analytics_stage, namespace: group, start_event_identifier: :merge_request_created, end_event_identifier: :merge_request_merged) }
  let_it_be(:common_stage_params) { { start_event_identifier: :issue_created, end_event_identifier: :issue_first_associated_with_milestone } }
  let_it_be(:stage_2) { create(:cycle_analytics_stage, namespace: group, **common_stage_params) }
  let_it_be(:stage_duplicate) { create(:cycle_analytics_stage, namespace: group, **common_stage_params) }
  let_it_be(:stage_triplicate) { create(:cycle_analytics_stage, namespace: group, **common_stage_params) }

  let_it_be(:project) { create(:project, group: group) }

  subject(:distinct_stages) { described_class.new(group: group).stages }

  it 'returns the distinct stages by stage_event_hash_id' do
    distinct_stage_hash_ids = subject.map(&:stage_event_hash_id)

    expect(distinct_stage_hash_ids).to eq(distinct_stage_hash_ids.uniq)
  end

  context 'when lead time and cycle time are not defined as stages' do
    it 'returns in-memory stages' do
      lead_time = distinct_stages.find { |stage| stage.name == 'lead time' }
      cycle_time = distinct_stages.find { |stage| stage.name == 'cycle time' }

      expect(lead_time).to be_present
      expect(cycle_time).to be_present
      expect(lead_time.stage_event_hash_id).not_to be_nil
      expect(cycle_time.stage_event_hash_id).not_to be_nil

      expect(lead_time.stage_event_hash_id).not_to eq(cycle_time.stage_event_hash_id)
    end

    it 'creates two stage event hash records' do
      expect { distinct_stages }.to change { Analytics::CycleAnalytics::StageEventHash.count }.by(2)
    end

    it 'returns 4 stages' do
      expect(distinct_stages.size).to eq(4)
    end
  end

  context 'when lead time and cycle time are persisted stages' do
    let_it_be(:cycle_time) do
      create(:cycle_analytics_stage,
             namespace: group,
             start_event_identifier: :issue_created,
             end_event_identifier: :issue_first_associated_with_milestone)
    end

    let_it_be(:lead_tiem) do
      create(:cycle_analytics_stage,
             namespace: group,
             start_event_identifier: :issue_created,
             end_event_identifier: :issue_first_associated_with_milestone)
    end

    it 'does not create extra stage event hash records' do
      expect { distinct_stages }.to change { Analytics::CycleAnalytics::StageEventHash.count }
    end
  end
end
