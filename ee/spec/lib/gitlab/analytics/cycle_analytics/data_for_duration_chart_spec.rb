# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::DataForDurationChart do
  describe '#average_by_day' do
    let_it_be(:project) { create(:project, :repository) }

    let(:query) { MergeRequest.joins(:metrics) }
    let(:merge_time) { 2.days.ago }

    let(:stage) do
      build(
        :cycle_analytics_stage,
        start_event_identifier: Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestCreated.identifier,
        end_event_identifier: Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestMerged.identifier,
        project: project
      )
    end

    subject(:averages) { described_class.new(stage: stage, params: {}, query: query).average_by_day }

    it 'returns average duration by day' do
      merge_request1 = create(:merge_request, source_branch: '1', target_project: project, source_project: project, created_at: merge_time - 5.minutes)
      merge_request2 = create(:merge_request, source_branch: '2', target_project: project, source_project: project, created_at: merge_time - 10.minutes)

      merge_request1.metrics.update!(merged_at: merge_time)
      merge_request2.metrics.update!(merged_at: merge_time)

      average = averages.take
      expect(average.date).to eq(merge_time.utc.to_date)
      expect(average.average_duration_in_seconds.to_i).to eq(7.5.minutes)
    end
  end
end
