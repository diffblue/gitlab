# frozen_string_literal: true
require 'spec_helper'

RSpec.describe AppSec::Dast::ProfileScheduleWorker, feature_category: :dynamic_application_security_testing do
  include ExclusiveLeaseHelpers

  let_it_be(:plan_limits) { create(:plan_limits, :default_plan) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:schedule) { create(:dast_profile_schedule, owner: owner, project: project) }

  let(:worker) { described_class.new }
  let(:logger) { worker.send(:logger) }
  let(:service) { instance_double(::AppSec::Dast::Scans::CreateService) }
  let(:service_result) { ServiceResponse.success }

  before do
    project.add_developer(owner)

    allow(::AppSec::Dast::Scans::CreateService)
      .to receive(:new)
      .and_return(service)
    allow(service).to receive(:execute)
      .and_return(service_result)
  end

  describe '#perform' do
    subject { worker.perform }

    context 'when feature is licensed' do
      before do
        stub_licensed_features(security_on_demand_scans: true)
      end

      context 'when multiple schedules exists' do
        before do
          schedule.update_column(:next_run_at, 1.minute.from_now)
        end

        def record_preloaded_queries
          recorder = ActiveRecord::QueryRecorder.new { subject }
          recorder.data.values.flat_map { |v| v[:occurrences] }.select do |query|
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

        context 'when all of the schedule owners are invalid' do
          before do
            travel_to(30.minutes.ago) { create_list(:dast_profile_schedule, 5, owner: nil, active: true) }
          end

          it 'sets active to false' do
            expect { subject }.to change { Dast::ProfileSchedule.where(active: false).count }.to(5)
          end
        end

        context 'when some of the schedule owners are invalid' do
          before do
            travel_to(30.minutes.ago) do
              create_list(:dast_profile_schedule, 2, owner: nil, active: true)
              create_list(:dast_profile_schedule, 3, owner: owner, active: true, project: project)
            end
          end

          it 'sets active to false', :aggregate_failures do
            expect(service).to receive(:execute)

            subject

            expect(Dast::ProfileSchedule.where(active: false).count).to eq(2)
          end
        end
      end

      context 'when schedule exists' do
        before do
          schedule.update_column(:next_run_at, 1.minute.ago)
        end

        it 'executes the service that creates dast scans', :aggregate_failures do
          expect_next_found_instance_of(::Dast::ProfileSchedule) do |schedule|
            expect(schedule).to receive(:schedule_next_run!)
          end

          expect(service).to receive(:execute)

          subject
        end

        it 'calls the service that creates dast scans with the correct parameters' do
          expect(::AppSec::Dast::Scans::CreateService).to receive(:new).with(container: project, current_user: owner, params: { dast_profile: schedule.dast_profile })

          subject
        end

        context 'when the schedule owner is invalid' do
          before do
            schedule.update_column(:user_id, nil)
            schedule.update_column(:active, true)
          end

          it 'sets active to false' do
            expect { subject }.to change { schedule.reload.active }.to(false)
          end
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

        it 'does not execute the service that creates dast scans' do
          expect(::AppSec::Dast::Scans::CreateService).not_to receive(:new)

          subject
        end
      end

      context 'when a schedule that does not repeat exists' do
        before do
          schedule.update_columns(next_run_at: 1.minute.ago, cadence: {})
        end

        it 'sets active to false', :aggregate_failures do
          expect(schedule.repeat?).to be(false)

          subject

          expect(schedule.reload.active).to be(false)
        end
      end
    end
  end
end
