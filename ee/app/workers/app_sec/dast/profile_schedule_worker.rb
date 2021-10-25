# frozen_string_literal: true

module AppSec
  module Dast
    class ProfileScheduleWorker
      include ApplicationWorker
      include CronjobQueue

      deduplicate :until_executed, including_scheduled: true
      idempotent!

      feature_category :dynamic_application_security_testing

      data_consistency :always

      def perform
        dast_runnable_schedules.find_in_batches do |schedules|
          schedules.each do |schedule|
            if schedule.owner_valid?
              execute_schedule(schedule)
            else
              schedule.deactivate!
            end
          end
        end
      end

      private

      def dast_runnable_schedules
        ::Dast::ProfileSchedule.with_project.with_profile.with_owner.runnable_schedules
      end

      def service(schedule)
        ::AppSec::Dast::Scans::CreateService.new(
          container: schedule.project,
          current_user: schedule.owner,
          params: { dast_profile: schedule.dast_profile }
        )
      end

      def execute_schedule(schedule)
        with_context(project: schedule.project, user: schedule.owner) do
          schedule.schedule_next_run!

          response = service(schedule).execute
          if response.error?
            logger.info(structured_payload(message: response.message))
          end
        end
      end
    end
  end
end
