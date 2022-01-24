# frozen_string_literal: true

module IncidentManagement
  module OncallSchedules
    class UpdateService < OncallSchedules::BaseService
      def execute(oncall_schedule)
        return error_no_license unless available?
        return error_no_permissions unless allowed?

        IncidentManagement::OncallSchedule.transaction do
          oncall_schedule.update!(params)
          update_rotations!(oncall_schedule)
        end

        success(oncall_schedule)
      rescue ActiveRecord::RecordInvalid => e
        error(e.record.errors.full_messages.to_sentence)
      rescue StandardError => e
        error(e.message)
      end

      private

      def update_rotations!(oncall_schedule)
        return unless oncall_schedule.timezone_previously_changed?

        update_rotation_active_periods!(oncall_schedule)
      end

      # Converts & updates the active period to the new timezone
      # Ex: 8:00 - 17:00 Europe/Berlin becomes 6:00 - 15:00 UTC
      def update_rotation_active_periods!(oncall_schedule)
        original_schedule_current_time = Time.current.in_time_zone(oncall_schedule.timezone_previously_was)

        oncall_schedule.rotations.with_active_period.each do |rotation|
          active_period = rotation.active_period.for_date(original_schedule_current_time)
          new_start_time, new_end_time = active_period.map { |time| time.in_time_zone(oncall_schedule.timezone).strftime('%H:%M') }

          service = IncidentManagement::OncallRotations::EditService.new(
            rotation,
            current_user,
            {
              active_period_start: new_start_time,
              active_period_end: new_end_time
            }
          )

          response = service.execute

          raise response.message if response.error?
        end
      end

      def error_no_permissions
        error(_('You have insufficient permissions to update an on-call schedule for this project'))
      end
    end
  end
end
