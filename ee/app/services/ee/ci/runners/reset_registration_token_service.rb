# frozen_string_literal: true

module EE
  module Ci
    module Runners
      module ResetRegistrationTokenService
        extend ::Gitlab::Utils::Override
        include ::Audit::Changes

        override :execute
        def execute
          previous_registration_token = runners_token

          result = super
          if result.success?
            audit_event(previous_registration_token, result.payload[:new_registration_token])
          end

          result
        end

        private

        def runners_token
          if scope.respond_to?(:runners_registration_token)
            scope.runners_registration_token
          else
            scope.runners_token
          end
        end

        def audit_event(previous_registration_token, new_registration_token)
          ::AuditEvents::RunnersTokenAuditEventService.new(
            user,
            scope,
            previous_registration_token,
            new_registration_token).security_event
        end
      end
    end
  end
end
