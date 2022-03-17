# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::ConsistencyWorker do
  def run_worker
    described_class.new.perform
  end

  context 'when the vsa_incremental_worker feature flag is off' do
    before do
      stub_feature_flags(vsa_consistency_worker: false)
    end

    it 'does nothing' do
      expect(Analytics::CycleAnalytics::Aggregation).not_to receive(:load_batch)

      run_worker
    end
  end

  context 'when the vsa_consistency_worker feature flag is on' do
    before do
      stub_feature_flags(vsa_consistency_worker: true)
    end

    context 'when no pending aggregation records present' do
      before do
        expect(Analytics::CycleAnalytics::Aggregation).to receive(:load_batch).once.and_call_original
      end

      it 'does nothing' do
        freeze_time do
          aggregation = create(:cycle_analytics_aggregation, last_consistency_check_updated_at: 5.minutes.from_now)

          expect { run_worker }.not_to change { aggregation.reload }
        end
      end
    end

    context 'when pending aggregation records present' do
      it 'invokes the consistency services' do
        aggregation1 = create(:cycle_analytics_aggregation, last_consistency_check_updated_at: 5.minutes.ago)
        aggregation2 = create(:cycle_analytics_aggregation, last_consistency_check_updated_at: 10.minutes.ago)

        freeze_time do
          run_worker

          expect(aggregation1.reload.last_consistency_check_updated_at).to eq(Time.current)
          expect(aggregation2.reload.last_consistency_check_updated_at).to eq(Time.current)
        end
      end
    end

    context 'when worker is over time' do
      it 'breaks at the second iteration due to overtime' do
        create_list(:cycle_analytics_aggregation, 2)

        first_monotonic_time = 100
        second_monotonic_time = first_monotonic_time + described_class::MAX_RUNTIME.to_i + 10

        expect(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(first_monotonic_time, second_monotonic_time)
        expect_next_instance_of(described_class) do |instance|
          expect(instance).to receive(:run_consistency_check_services).once
        end

        run_worker
      end
    end
  end
end
