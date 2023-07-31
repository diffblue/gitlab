# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::ValueStreamDashboard::CountWorker, :clean_gitlab_redis_shared_state, feature_category: :value_stream_management do
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
      allow(License).to receive(:feature_available?).and_return(true)
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

      context 'when a group downgraded and has no license', :saas do
        it 'disables the aggregation' do
          aggregation1 = create(:value_stream_dashboard_aggregation, last_run_at: nil)
          aggregation2 = create(:value_stream_dashboard_aggregation, last_run_at: nil)

          allow(aggregation1.namespace).to receive(:licensed_feature_available?)
            .with(:group_level_analytics_dashboard)
            .and_return(false)

          allow(aggregation2.namespace).to receive(:licensed_feature_available?)
            .with(:group_level_analytics_dashboard)
            .and_return(true)

          allow(Analytics::ValueStreamDashboard::Aggregation).to receive(:load_batch).and_return(
            [aggregation1, aggregation2], [])

          run_job

          expect(aggregation1.reload).not_to be_enabled
          expect(aggregation2.reload.last_run_at).to be_present
        end
      end

      context 'when loading a persisted cursor' do
        let_it_be(:first) { create(:value_stream_dashboard_aggregation, last_run_at: 15.days.ago) }
        let_it_be(:second) { create(:value_stream_dashboard_aggregation, last_run_at: nil) }

        let(:cursor) { { top_level_namespace_id: first.namespace_id } }

        before do
          Gitlab::Redis::SharedState.with do |redis|
            redis.set(described_class::CURSOR_KEY, Gitlab::Json.dump(cursor))
          end
        end

        def expect_service_invocation_for(aggregation, returned_payload)
          response = ServiceResponse.success(payload: returned_payload)
          service = instance_double('Analytics::ValueStreamDashboard::TopLevelGroupCounterService',
            execute: response)

          expect(Analytics::ValueStreamDashboard::TopLevelGroupCounterService).to receive(:new).with(
            aggregation: aggregation,
            cursor: an_instance_of(Gitlab::Analytics::ValueStreamDashboard::NamespaceCursor),
            runtime_limiter: an_instance_of(Analytics::CycleAnalytics::RuntimeLimiter)
          ).and_return(service)
        end

        it 'passes the cursor to the aggregation service' do
          cursor1 = Analytics::ValueStreamDashboard::TopLevelGroupCounterService.load_cursor(raw_cursor: {
            top_level_namespace_id: first.id
          })
          cursor2 = Analytics::ValueStreamDashboard::TopLevelGroupCounterService.load_cursor(raw_cursor: {
            top_level_namespace_id: second.id
          })

          expect_service_invocation_for(first, { cursor: cursor1, result: :finished })
          expect_service_invocation_for(second, { cursor: cursor2, result: :finished })

          run_job
        end

        it 'persists the new cursor' do
          cursor1 = Analytics::ValueStreamDashboard::TopLevelGroupCounterService.load_cursor(raw_cursor: {
            top_level_namespace_id: first.id
          })
          expect_service_invocation_for(first, { cursor: cursor1, result: :finished })

          interrupted_cursor = {
            top_level_namespace_id: second.namespace_id,
            metric: Analytics::ValueStreamDashboard::Count.metrics[:issues],
            last_value: 1,
            last_count: 2
          }

          cursor2 = Analytics::ValueStreamDashboard::TopLevelGroupCounterService
            .load_cursor(raw_cursor: interrupted_cursor)

          expect_service_invocation_for(second, { cursor: cursor2, result: :interrupted })

          expect_next_instance_of(Analytics::CycleAnalytics::RuntimeLimiter) do |runtime_limiter|
            # first aggregation, trigger no overtime
            expect(runtime_limiter).to receive(:over_time?).and_return(false)
          end

          run_job

          persisted_cursor = Gitlab::Redis::SharedState.with { |redis| redis.get(described_class::CURSOR_KEY) }
          parsed_cursor = Gitlab::Json.parse(persisted_cursor).symbolize_keys
          expect(parsed_cursor).to eq(interrupted_cursor)
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
