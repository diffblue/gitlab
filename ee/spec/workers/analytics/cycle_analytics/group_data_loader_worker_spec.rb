# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::GroupDataLoaderWorker do
  let(:group_id) { nil }
  let(:model_klass) { 'Issue' }
  let(:updated_at_before) { Time.current }
  let(:worker) { described_class.new }

  def run_worker
    worker.perform(group_id, model_klass, {}, updated_at_before)
  end

  context 'when non-existing group is given' do
    let(:group_id) { non_existing_record_id }

    it 'does nothing' do
      expect(Analytics::CycleAnalytics::DataLoaderService).not_to receive(:new)

      expect(run_worker).to eq(nil)
    end
  end

  context 'when invalid model klass is given' do
    let(:group_id) { create(:group).id }
    let(:model_klass) { 'unknown' }

    it 'does nothing' do
      expect(Analytics::CycleAnalytics::DataLoaderService).not_to receive(:new)

      expect(run_worker).to eq(nil)
    end
  end

  context 'when the data loader returns error response' do
    let(:group_id) { create(:group) }

    it 'logs the error reason' do
      expect(worker).to receive(:log_extra_metadata_on_done).with(:error_reason, :missing_license)

      run_worker
    end
  end

  context 'when DataLoaderService is invoked successfully' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:group_id) { group.id }
    let_it_be(:stage) { create(:cycle_analytics_group_stage, group: group, start_event_identifier: :issue_created, end_event_identifier: :issue_closed) }
    let_it_be(:issue1) { create(:issue, project: project, updated_at: 5.days.ago) }
    let_it_be(:issue2) { create(:issue, project: project, updated_at: 10.days.ago) }

    before do
      stub_licensed_features(cycle_analytics_for_groups: true)
    end

    context 'when limit_reached status is returned' do
      before do
        stub_const('Analytics::CycleAnalytics::DataLoaderService::BATCH_LIMIT', 1)
        stub_const('Analytics::CycleAnalytics::DataLoaderService::MAX_UPSERT_COUNT', 1)
      end

      it 'schedules a new job with the returned cursor' do
        expect(described_class).to receive(:perform_in).with(
          2.minutes,
          group_id,
          'Issue',
          hash_including('id' => issue2.id.to_s), # cursor, the next job continues the processing after this record
          updated_at_before
        )

        run_worker
      end
    end

    context 'when model_processed status is returned' do
      context 'when there is a next model to process' do
        it 'schedules a new job with the MergeRequest model' do
          expect(described_class).to receive(:perform_in).with(
            2.minutes,
            group_id,
            'MergeRequest',
            {},
            updated_at_before
          )

          run_worker # Issue related records are processed
        end
      end

      context 'when there is no next model to process' do
        let(:model_klass) { 'MergeRequest' }

        it 'stops the execution' do
          expect(described_class).not_to receive(:perform_in)

          run_worker # after this call, there is no more records to be processed
        end
      end
    end
  end
end
