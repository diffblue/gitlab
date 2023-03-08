# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::DataLoaderService do
  let_it_be_with_refind(:top_level_group) { create(:group) }

  describe 'validations' do
    let(:group) { top_level_group }
    let(:model) { Issue }

    subject(:service_response) { described_class.new(group: group, model: model).execute }

    context 'when wrong model is passed' do
      let(:model) { Project }

      it 'returns service error response' do
        expect(service_response).to be_error
        expect(service_response.payload[:reason]).to eq(:invalid_model)
      end
    end

    context 'when license is missing' do
      it 'returns service error response' do
        expect(service_response).to be_error
        expect(service_response.payload[:reason]).to eq(:missing_license)
      end
    end

    context 'when sub-group is given' do
      let(:group) { create(:group, parent: top_level_group) }

      it 'returns service error response' do
        stub_licensed_features(cycle_analytics_for_groups: true)

        expect(service_response).to be_error
        expect(service_response.payload[:reason]).to eq(:requires_top_level_group)
      end
    end
  end

  describe 'data loading into stage tables' do
    let_it_be(:sub_group) { create(:group, parent: top_level_group) }
    let_it_be(:other_group) { create(:group) }
    let_it_be(:project1) { create(:project, :repository, group: top_level_group) }
    let_it_be(:project2) { create(:project, :repository, group: sub_group) }
    let_it_be(:project_outside) { create(:project, group: other_group) }

    let_it_be(:stage1) do
      create(:cycle_analytics_stage, {
        namespace: sub_group,
        start_event_identifier: :merge_request_created,
        end_event_identifier: :merge_request_merged
      })
    end

    let_it_be(:stage2) do
      create(:cycle_analytics_stage, {
        namespace: top_level_group,
        start_event_identifier: :issue_created,
        end_event_identifier: :issue_closed
      })
    end

    let_it_be(:stage_in_other_group) do
      create(:cycle_analytics_stage, {
        namespace: other_group,
        start_event_identifier: :issue_created,
        end_event_identifier: :issue_closed
      })
    end

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)
    end

    it 'loads nothing for Issue model' do
      service_response = described_class.new(group: top_level_group, model: Issue).execute

      expect(service_response).to be_success
      expect(service_response.payload[:reason]).to eq(:model_processed)
      expect(Analytics::CycleAnalytics::IssueStageEvent.count).to eq(0)
      expect(service_response[:context].processed_records).to eq(0)
    end

    it 'loads nothing for MergeRequest model' do
      service_response = described_class.new(group: top_level_group, model: MergeRequest).execute

      expect(service_response).to be_success
      expect(service_response.payload[:reason]).to eq(:model_processed)
      expect(Analytics::CycleAnalytics::MergeRequestStageEvent.count).to eq(0)
      expect(service_response[:context].processed_records).to eq(0)
    end

    context 'when MergeRequest data is present' do
      let_it_be(:mr1) { create(:merge_request, :unique_branches, :with_merged_metrics, updated_at: 2.days.ago, source_project: project1) }
      let_it_be(:mr2) { create(:merge_request, :unique_branches, :with_merged_metrics, updated_at: 5.days.ago, source_project: project1) }
      let_it_be(:mr3) { create(:merge_request, :unique_branches, :with_merged_metrics, updated_at: 10.days.ago, source_project: project2) }

      it 'inserts stage records' do
        expected_data = [mr1, mr2, mr3].map do |mr|
          mr.reload # reload timestamps from the DB
          [
            mr.id,
            mr.project.parent_id,
            mr.project_id,
            mr.created_at,
            mr.metrics.merged_at,
            mr.state_id
          ]
        end

        described_class.new(group: top_level_group, model: MergeRequest).execute

        events = Analytics::CycleAnalytics::MergeRequestStageEvent.all
        event_data = events.map do |event|
          [
            event.merge_request_id,
            event.group_id,
            event.project_id,
            event.start_event_timestamp,
            event.end_event_timestamp,
            Analytics::CycleAnalytics::MergeRequestStageEvent.states[event.state_id]
          ]
        end

        expect(event_data.sort).to match_array(expected_data.sort)
      end

      it 'inserts nothing for group outside of the hierarchy' do
        mr = create(:merge_request, :unique_branches, :with_merged_metrics, source_project: project_outside)

        described_class.new(group: top_level_group, model: MergeRequest).execute

        record_count = Analytics::CycleAnalytics::MergeRequestStageEvent.where(merge_request_id: mr.id).count
        expect(record_count).to eq(0)
      end

      context 'when all records are processed' do
        it 'finishes with model_processed reason' do
          service_response = described_class.new(group: top_level_group, model: MergeRequest).execute

          expect(service_response).to be_success
          expect(service_response.payload[:reason]).to eq(:model_processed)
        end
      end

      context 'when MAX_UPSERT_COUNT is reached' do
        it 'finishes with limit_reached reason' do
          stub_const('Analytics::CycleAnalytics::DataLoaderService::MAX_UPSERT_COUNT', 1)
          stub_const('Analytics::CycleAnalytics::DataLoaderService::BATCH_LIMIT', 1)

          service_response = described_class.new(group: top_level_group, model: MergeRequest).execute

          expect(service_response).to be_success
          expect(service_response.payload[:reason]).to eq(:limit_reached)
        end
      end

      context 'when runtime limit is reached' do
        it 'finishes with limit_reached reason' do
          first_monotonic_time = 100
          second_monotonic_time = first_monotonic_time + Analytics::CycleAnalytics::RuntimeLimiter::DEFAULT_MAX_RUNTIME.to_i + 10

          # 1. when initializing the runtime limiter
          # 2. when start the processing
          # 3. when calling over_time? within the rate limiter
          # 4. when calculating the aggregation duration
          expect(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(first_monotonic_time, first_monotonic_time, second_monotonic_time, second_monotonic_time)

          service_response = described_class.new(group: top_level_group, model: MergeRequest).execute

          expect(service_response).to be_success
          expect(service_response.payload[:reason]).to eq(:limit_reached)
        end
      end

      context 'when cursor is given' do
        it 'continues processing the records from the cursor' do
          stub_const('Analytics::CycleAnalytics::DataLoaderService::MAX_UPSERT_COUNT', 1)
          stub_const('Analytics::CycleAnalytics::DataLoaderService::BATCH_LIMIT', 1)

          service_response = described_class.new(group: top_level_group, model: MergeRequest).execute
          ctx = service_response.payload[:context]

          expect(Analytics::CycleAnalytics::MergeRequestStageEvent.count).to eq(1)

          described_class.new(group: top_level_group, model: MergeRequest, context: ctx).execute

          expect(Analytics::CycleAnalytics::MergeRequestStageEvent.count).to eq(2)
          expect(ctx.processed_records).to eq(2)
          expect(ctx.runtime).to be > 0
        end
      end
    end

    context 'when Issue data is present' do
      let_it_be(:issue1) { create(:issue, project: project1, closed_at: 5.minutes.from_now) }
      let_it_be(:issue2) { create(:issue, project: project1, closed_at: 5.minutes.from_now) }
      let_it_be(:issue3) { create(:issue, project: project2, closed_at: 5.minutes.from_now) }
      # invalid the creation time would be later than closed_at, this should not be aggregated
      let_it_be(:issue4) { create(:issue, project: project2, closed_at: 5.minutes.ago) }

      it 'inserts stage records' do
        expected_data = [issue1, issue2, issue3].map do |issue|
          issue.reload
          [
            issue.id,
            issue.project.parent_id,
            issue.project_id,
            issue.created_at,
            issue.closed_at,
            issue.state_id
          ]
        end

        described_class.new(group: top_level_group, model: Issue).execute

        events = Analytics::CycleAnalytics::IssueStageEvent.all
        event_data = events.map do |event|
          [
            event.issue_id,
            event.group_id,
            event.project_id,
            event.start_event_timestamp,
            event.end_event_timestamp,
            Analytics::CycleAnalytics::IssueStageEvent.states[event.state_id]
          ]
        end

        expect(event_data.sort).to match_array(expected_data.sort)
      end
    end
  end
end
