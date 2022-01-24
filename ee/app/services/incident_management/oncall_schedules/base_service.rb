# frozen_string_literal: true

module IncidentManagement
  module OncallSchedules
    class BaseService < ::BaseProjectService
      def allowed?
        current_user&.can?(:admin_incident_management_oncall_schedule, project)
      end

      def available?
        ::Gitlab::IncidentManagement.oncall_schedules_available?(project)
      end

      def error(message)
        ServiceResponse.error(message: message)
      end

      def success(oncall_schedule)
        ServiceResponse.success(payload: { oncall_schedule: oncall_schedule })
      end

      def error_no_license
        error(_('Your license does not support on-call schedules'))
      end
    end
  end
end
