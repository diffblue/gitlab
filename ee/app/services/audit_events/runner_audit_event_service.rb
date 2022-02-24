# frozen_string_literal: true

module AuditEvents
  class RunnerAuditEventService < ::AuditEventService
    # Logs an audit event related to a runner event
    #
    # @param [Ci::Runner] runner
    # @param [String, User] author the entity initiating the operation (e.g. a runner registration or authentication token)
    # @param [Group, Project, nil] token_scope the scopes that the operation applies to (nil represents the instance)
    def initialize(runner, author, token_scope)
      @token_scope = token_scope
      @runner = runner

      raise ArgumentError, 'Missing token_scope' if token_scope.nil? && !runner.instance_type?

      details = {
        custom_message: message,
        target_id: runner.id,
        target_type: runner.class.name,
        target_details: runner_path
      }

      if author.is_a?(String)
        author = author[0...8]
        details[token_field] = author
      end

      details[:errors] = @runner.errors.full_messages unless @runner.errors.empty?

      super(author, token_scope, details)
    end

    def track_event
      return unless message
      return security_event if @token_scope

      unauth_security_event
    end

    private

    def message
      raise NotImplementedError, "Please implement #{self.class}##{__method__}"
    end

    def runner_type
      @runner.runner_type.chomp('_type')
    end

    def runner_path
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
