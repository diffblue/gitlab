# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::AggregatorService do
  let!(:group) { create(:group) }
  let!(:aggregation) { create(:cycle_analytics_aggregation, :enabled, namespace: group) }
  let(:mode) { :incremental }

  def run_service
    described_class.new(aggregation: aggregation, mode: mode).execute
  end

  context 'when invalid mode is given' do
    let(:mode) { :other_mode }

    it 'raises error' do
      expect { run_service }.to raise_error /Only :incremental and :full modes are supported/
    end
  end

  context 'when the group is not licensed' do
    it 'sets the aggregation record disabled' do
      expect { run_service }.to change { aggregation.reload.enabled }.from(true).to(false)
    end

    it 'calls the DataLoaderService only once' do
      expect(Analytics::CycleAnalytics::DataLoaderService).to receive(:new).once.and_call_original

      run_service
    end
  end

  context 'when a subgroup is given' do
    let(:group) { create(:group, parent: create(:group)) }

    it 'sets the aggregation record disabled' do
      stub_licensed_features(cycle_analytics_for_groups: true)

      expect { run_service }.to change { aggregation.reload.enabled }.from(true).to(false)
    end
  end

  context 'when the aggregation succeeds' do
    before do
      stub_licensed_features(cycle_analytics_for_groups: true)
    end

    context 'when nothing to aggregate' do
      it 'updates the aggregation record with metadata' do
        freeze_time do
          run_service

          expect(aggregation.reload).to have_attributes(
            incremental_runtimes_in_seconds: satisfy(&:one?),
            incremental_processed_records: [0],
            last_incremental_run_at: Time.current,
            last_incremental_merge_requests_updated_at: nil,
            last_incremental_merge_requests_id: nil,
            last_incremental_issues_updated_at: nil,
            last_incremental_issues_id: nil
          )
        end
      end

      context 'when the aggregation already contains metadata about the previous runs' do
        before do
          # we store data for the last 10 runs
          aggregation.update!(
            incremental_processed_records: [1000] * 10,
            incremental_runtimes_in_seconds: [100] * 10
          )
        end

        it 'updates the statistical columns' do
          run_service

          aggregation.reload

          expect(aggregation.incremental_processed_records.length).to eq(10)
          expect(aggregation.incremental_runtimes_in_seconds.length).to eq(10)
          expect(aggregation.incremental_processed_records[-1]).to eq(0)
          expect(aggregation.incremental_processed_records[-1]).not_to eq(100)
        end
      end
    end

    context 'when merge requests and issues are present for the configured VSA stages' do
      let(:project) { create(:project, group: group) }
      let!(:merge_request) { create(:merge_request, :with_merged_metrics, project: project) }
      let!(:issue1) { create(:issue, project: project, closed_at: Time.current) }
      let!(:issue2) { create(:issue, project: project, closed_at: Time.current) }

      before do
        create(:cycle_analytics_stage,
               namespace: group,
               start_event_identifier: :merge_request_created,
               end_event_identifier: :merge_request_merged
              )

        create(:cycle_analytics_stage,
               namespace: group,
               start_event_identifier: :issue_created,
               end_event_identifier: :issue_closed
              )
      end

      it 'updates the aggregation record with record count and the last cursor' do
        run_service

        expect(aggregation.reload).to have_attributes(
          incremental_processed_records: [3],
          last_incremental_merge_requests_updated_at: be_within(5.seconds).of(merge_request.updated_at),
          last_incremental_merge_requests_id: merge_request.id,
          last_incremental_issues_updated_at: be_within(5.seconds).of(issue2.updated_at),
          last_incremental_issues_id: issue2.id
        )
      end
    end

    context 'when running a full aggregation' do
      let(:mode) { :full }

      let(:project) { create(:project, group: group) }
      let!(:merge_request_1) { create(:merge_request, :with_merged_metrics, :unique_branches, project: project) }
      let!(:merge_request_2) { create(:merge_request, :with_merged_metrics, :unique_branches, project: project) }

      before do
        create(:cycle_analytics_stage,
               namespace: group,
               start_event_identifier: :merge_request_created,
               end_event_identifier: :merge_request_merged
              )

        stub_const('Analytics::CycleAnalytics::DataLoaderService::MAX_UPSERT_COUNT', 1)
        stub_const('Analytics::CycleAnalytics::DataLoaderService::UPSERT_LIMIT', 1)
        stub_const('Analytics::CycleAnalytics::DataLoaderService::BATCH_LIMIT', 1)
      end

      context 'when aggregation is not finished' do
        it 'persists the cursor attributes' do
          run_service

          expect(aggregation.reload).to have_attributes(
            full_processed_records: [1],
            last_full_merge_requests_updated_at: be_within(5.seconds).of(merge_request_1.updated_at),
            last_full_merge_requests_id: merge_request_1.id,
            last_full_issues_updated_at: nil,
            last_full_issues_id: nil
          )
        end
      end

      context 'when aggregation is finished during the second run' do
        it 'resets the cursor attributes so the aggregation starts from the beginning' do
          3.times { run_service }

          expect(aggregation.reload).to have_attributes(
            full_processed_records: [1, 1, 0],
            last_full_merge_requests_updated_at: nil,
            last_full_merge_requests_id: nil,
            last_full_issues_updated_at: nil,
            last_full_issues_id: nil
          )
        end
      end
    end
  end
end
