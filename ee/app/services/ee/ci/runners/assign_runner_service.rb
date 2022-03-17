# frozen_string_literal: true

module EE
  module Ci
    module Runners
      module AssignRunnerService
        extend ::Gitlab::Utils::Override
        include ::Audit::Changes

        override :execute
        def execute
          result = super

          audit_log_event if result

          result
        end

        private

        AUDIT_MESSAGE = 'Assigned CI runner to project'

        def audit_log_event
          ::AuditEvents::RunnerCustomAuditEventService.new(runner, user, project, AUDIT_MESSAGE).track_event
        end
      end
    end
  end
end
