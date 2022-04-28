# frozen_string_literal: true

module AuditEvents
  class RunnersTokenAuditEventService < ::AuditEventService
    include SafeRunnerToken

    # Logs an audit event related to a runner event
    #
    # @param [User] author the user initiating the operation
    # @param [Group, Project, ApplicationSetting] scope the scope that the operation applies to
    # @param [String] previous_registration_token the previous registration token associated with scope
    # @param [String] new_registration_token the new registration token associated with scope
    def initialize(author, scope, previous_registration_token, new_registration_token)
      @scope = scope

      raise ArgumentError, 'Missing scope' unless scope

      safe_scope = scope.is_a?(::ApplicationSetting) ? author : scope

      super(author, safe_scope, details(author, previous_registration_token, new_registration_token))
    end

    private

    def details(author, previous_registration_token, new_registration_token)
      details = {
        action: :custom,
        custom_message: message,
        from: safe_author(previous_registration_token),
        to: safe_author(new_registration_token)
      }

      details[:errors] = @scope.errors.full_messages unless @scope.errors.empty?

      details
    end

    def message
      return 'Reset instance runner registration token' if @scope.is_a?(::ApplicationSetting)

      "Reset #{@scope.class.name.downcase} runner registration token"
    end
  end
end
