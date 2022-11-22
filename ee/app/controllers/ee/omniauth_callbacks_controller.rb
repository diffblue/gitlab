# frozen_string_literal: true

module EE
  module OmniauthCallbacksController
    extend ::Gitlab::Utils::Override

    private

    override :log_failed_login
    def log_failed_login(author, provider)
      ::AuditEventService.new(
        author,
        nil,
        with: provider
      ).for_failed_login.unauth_security_event
    end
  end
end
