# frozen_string_literal: true

module AuditEvents
  class RunnerRegistrationAuditEventService < ::AuditEventService
    def initialize(runner, registration_token, token_scope, action)
      @token_scope = token_scope
      @runner = runner
      @action = action

      raise ArgumentError, 'Missing token_scope' if token_scope.nil? && !runner.instance_type?

      details = {
        custom_message: message,
        target_id: runner.id,
        target_type: runner.class.name,
        target_details: runner_path,
        runner_registration_token: registration_token[0...8]
      }
      details[:errors] = @runner.errors.full_messages unless @runner.errors.empty?

      super(details[:runner_registration_token], token_scope, details)
    end

    def track_event
      return unless message
      return security_event if @token_scope

      unauth_security_event
    end

    def message
      runner_type = @runner.runner_type.chomp('_type')

      case @action
      when :register
        if @runner.valid?
          "Registered #{runner_type} CI runner"
        else
          "Failed to register #{runner_type} CI runner"
        end
      end
    end

    def runner_path
      return unless @runner.persisted?

      url_helpers = ::Gitlab::Routing.url_helpers

      if @runner.group_type?
        url_helpers.group_runner_path(@token_scope, @runner)
      elsif @runner.project_type?
        url_helpers.project_runner_path(@token_scope, @runner)
      else
        url_helpers.admin_runner_path(@runner)
      end
    end
  end
end
