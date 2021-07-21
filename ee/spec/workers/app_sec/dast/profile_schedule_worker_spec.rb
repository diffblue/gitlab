# frozen_string_literal: true
require 'spec_helper'

RSpec.describe AppSec::Dast::ProfileScheduleWorker do
  include ExclusiveLeaseHelpers

  let_it_be(:schedule) { create(:dast_profile_schedule) }

  let(:worker) { described_class.new }
  let(:logger) { worker.send(:logger) }
  let(:service) { instance_double(::DastOnDemandScans::CreateService) }
  let(:service_result) { ServiceResponse.success }

  before do
    allow(::DastOnDemandScans::CreateService)
      .to receive(:new)
      .and_return(service)
    allow(service).to receive(:execute)
      .and_return(service_result)
  end

  describe '#perform' do
    subject { worker.perform }

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(dast_on_demand_scans_scheduler: false)
      end

      it 'does not call runnable_schedules' do
        expect(::Dast::ProfileSchedule).not_to receive(:runnable_schedules)
        subject
      end
    end

    context 'when multiple schedules exists' do
      before do
        schedule.update_column(:next_run_at, 1.minute.from_now)
      end

      def record_preloaded_queries
        recorder = ActiveRecord::QueryRecorder.new { subject }
        recorder.data.values.flat_map {|v| v[:occurrences]}.select do |query|
          ['FROM "projects"', 'FROM "users"', 'FROM "dast_profile"', 'FROM "dast_profile_schedule"'].any? do |s|
            query.include?(s)
          end
        end
      end

      it 'preloads configuration, project and owner to avoid N+1 queries' do
        expected_count = record_preloaded_queries.count

        travel_to(30.minutes.ago) { create_list(:dast_profile_schedule, 5) }
        actual_count = record_preloaded_queries.count

        expect(actual_count).to eq(expected_count)
      end
    end

    context 'when schedule exists' do
      before do
        schedule.update_column(:next_run_at, 1.minute.ago)
      end

      it 'executes the rule schedule service' do
        expect_next_found_instance_of(::Dast::ProfileSchedule) do |schedule|
          expect(schedule).to receive(:schedule_next_run!)
        end

        expect(service).to receive(:execute)

        subject
      end
    end

    context 'when service returns an error' do
      before do
        schedule.update_column(:next_run_at, 1.minute.ago)
      end

      let(:error_message) { 'some message' }
      let(:service_result) { ServiceResponse.error(message: error_message) }

      it 'succeeds and logs the error' do
        expect(logger)
          .to receive(:info)
          .with(a_hash_including('message' => error_message))

        subject
      end
    end

    context 'when schedule does not exist' do
      before do
        schedule.update_column(:next_run_at, 1.minute.from_now)
      end

      it 'executes the rule schedule service' do
        expect(::DastOnDemandScans::CreateService).not_to receive(:new)

        subject
      end
    end
  end
end
