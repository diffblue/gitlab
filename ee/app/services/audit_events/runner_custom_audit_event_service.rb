# frozen_string_literal: true

module AuditEvents
  class RunnerCustomAuditEventService < RunnerAuditEventService
    # Logs an audit event with a custom message related to a runner event
    #
    # @param [Ci::Runner] runner
    # @param [String, User] author: the entity initiating the operation (e.g. a runner registration or authentication token)
    # @param [Group, Project, nil] token_scope: the scopes that the operation applies to (nil represents the instance)
    # @param [String] custom_message: the message describing the event
    def initialize(runner, author, token_scope, custom_message)
      @custom_message = custom_message

      super(runner, author, token_scope)
    end

    def message
      @custom_message
    end
  end
end
