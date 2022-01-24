# frozen_string_literal: true

module IncidentManagement
  module OncallSchedules
    class DestroyService < OncallSchedules::BaseService
      def execute(oncall_schedule)
        return error_no_license unless available?
        return error_no_permissions unless allowed?

        if oncall_schedule.destroy
          success(oncall_schedule)
        else
          error(oncall_schedule.errors.full_messages.to_sentence)
        end
      end

      private

      def error_no_permissions
        error(_('You have insufficient permissions to remove an on-call schedule from this project'))
      end
    end
  end
end
