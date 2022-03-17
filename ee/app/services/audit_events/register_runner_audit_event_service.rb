# frozen_string_literal: true

module AuditEvents
  class RegisterRunnerAuditEventService < RunnerAuditEventService
    def token_field
      :runner_registration_token
    end

    def message
      return "Registered #{runner_type} CI runner" if @runner.valid?

      "Failed to register #{runner_type} CI runner"
    end

    def runner_path
      super if @runner.persisted?
    end
  end
end
