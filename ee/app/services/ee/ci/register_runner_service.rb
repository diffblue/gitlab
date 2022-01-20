# frozen_string_literal: true

module EE
  module Ci
    module RegisterRunnerService
      extend ::Gitlab::Utils::Override
      include ::Audit::Changes

      override :execute
      def execute(registration_token, attributes)
        runner = super(registration_token, attributes)

        audit_log_event(runner, registration_token) if runner

        runner
      end

      private

      def audit_log_event(runner, registration_token)
        ::AuditEvents::RunnerRegistrationAuditEventService.new(runner, registration_token, token_scope, :register)
          .track_event
      end
    end
  end
end
