# frozen_string_literal: true

module EE
  module Ci
    module Runners
      module UnassignRunnerService
        extend ::Gitlab::Utils::Override
        include ::Audit::Changes

        override :execute
        def execute
          runner = runner_project.runner
          project = runner_project.project
          result = super

          audit_log_event(runner, project) if result

          result
        end

        private

        AUDIT_MESSAGE = 'Unassigned CI runner from project'

        def audit_log_event(runner, project)
          ::AuditEvents::RunnerCustomAuditEventService.new(runner, user, project, AUDIT_MESSAGE).track_event
        end
      end
    end
  end
end
