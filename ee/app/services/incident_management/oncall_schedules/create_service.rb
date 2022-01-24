# frozen_string_literal: true

module IncidentManagement
  module OncallSchedules
    class CreateService < OncallSchedules::BaseService
      def execute
        return error_no_license unless available?
        return error_no_permissions unless allowed?

        oncall_schedule = project.incident_management_oncall_schedules.create(params)
        return error_in_create(oncall_schedule) unless oncall_schedule.persisted?

        success(oncall_schedule)
      end

      private

      def error_no_permissions
        error(_('You have insufficient permissions to create an on-call schedule for this project'))
      end

      def error_in_create(oncall_schedule)
        error(oncall_schedule.errors.full_messages.to_sentence)
      end
    end
  end
end
