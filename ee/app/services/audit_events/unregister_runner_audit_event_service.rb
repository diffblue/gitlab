# frozen_string_literal: true

module AuditEvents
  class UnregisterRunnerAuditEventService < RunnerAuditEventService
    def token_field
      :runner_authentication_token
    end

    def message
      "Unregistered #{runner_type} CI runner"
    end
  end
end
