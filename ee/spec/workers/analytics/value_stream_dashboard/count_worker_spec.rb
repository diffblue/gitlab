# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::ValueStreamDashboard::CountWorker, feature_category: :value_stream_management do
  def run_job
    described_class.new.perform
  end

  context 'when the group_level_analytics_dashboard feature is not available' do
    it 'does nothing' do
      expect(Analytics::ValueStreamDashboard::Aggregation).not_to receive(:load_batch)

      run_job
    end
  end

  context 'when the group_level_analytics_dashboard feature is available' do
    before do
      stub_licensed_features(group_level_analytics_dashboard: true)
    end

    context 'when the current time is not close to the end of month' do
      it 'does nothing' do
        travel_to(Date.new(2022, 5, 15)) do
          expect(Analytics::ValueStreamDashboard::Aggregation).not_to receive(:load_batch)

          run_job
        end
      end
    end

    context 'when the current time is close to the end of month' do
      around do |example|
        travel_to(Date.new(2022, 2, 26)) do
          example.run
        end
      end

      context 'when no records present' do
        it 'does nothing' do
          expect(Analytics::ValueStreamDashboard::TopLevelGroupCounterService).not_to receive(:new)

          run_job
        end
      end

      context 'when records are returned' do
        it 'invokes the count service' do
          create_list(:value_stream_dashboard_aggregation, 3, last_run_at: nil)

          expect(Analytics::ValueStreamDashboard::TopLevelGroupCounterService).to receive(:new).thrice.and_call_original
          run_job

          last_run_at_values = Analytics::ValueStreamDashboard::Aggregation.pluck(:last_run_at)
          expect(last_run_at_values).to all(eq(Time.current))
        end
      end

      context 'when some records were processed recently' do
        it 'skips the recently processed record' do
          create(:value_stream_dashboard_aggregation, last_run_at: 3.days.ago) # should not be processed
          outdated_aggregation = create(:value_stream_dashboard_aggregation, last_run_at: 15.days.ago)

          run_job

          namespace_ids = Analytics::ValueStreamDashboard::Count.distinct.pluck(:namespace_id)
          expect(namespace_ids).to eq([outdated_aggregation.id])
        end
      end

      context 'when the execution is over time' do
        it 'stops the processing' do
          create_list(:value_stream_dashboard_aggregation, 3, last_run_at: nil)

          expect_next_instance_of(Analytics::CycleAnalytics::RuntimeLimiter) do |runtime_limiter|
            allow(runtime_limiter).to receive(:over_time?).and_return(true)
          end

          expect(Analytics::ValueStreamDashboard::TopLevelGroupCounterService).to receive(:new).once.and_call_original

          run_job
        end
      end
    end
  end
end
