# frozen_string_literal: true

module EE
  module PasswordsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      before_action :log_audit_event, only: [:create]
    end

    override :log_audit_reset_failure
    def log_audit_reset_failure(user)
      ::Audit::UserPasswordResetAuditor.new(user, user, request.remote_ip).audit_reset_failure
    end

    private

    def log_audit_event
      unauth_author = ::Gitlab::Audit::UnauthenticatedAuthor.new
      requester = resource || ::User.new(id: unauth_author.id)

      ::Gitlab::Audit::Auditor.audit({
        name: "password_reset_requested",
        author: current_user || unauth_author,
        scope: requester,
        target: requester,
        target_details: resource_params[:email],
        message: "Ask for password reset",
        ip_address: request.remote_ip
      })
    end
  end
end
