# frozen_string_literal: true

module EE
  module Ci
    module Runners
      module UnassignRunnerService
        extend ::Gitlab::Utils::Override
        include ::Audit::Changes

        override :execute
        def execute
          result = super

          audit_event if result.success?

          result
        end

        private

        AUDIT_MESSAGE = 'Unassigned CI runner from project'

        def audit_event
          ::AuditEvents::RunnerCustomAuditEventService.new(runner, user, project, AUDIT_MESSAGE).track_event
        end
      end
    end
  end
end
