# frozen_string_literal: true

module EE
  module PasswordsController
    extend ActiveSupport::Concern

    prepended do
      before_action :log_audit_event, only: [:create]
    end

    private

    def log_audit_event
      ::Gitlab::Audit::Auditor.audit({
        name: "password_reset_requested",
        author: ::Gitlab::Audit::UnauthenticatedAuthor.new,
        scope: resource,
        target: resource || ::User.new,
        target_details: resource_params[:email],
        message: "Ask for password reset",
        ip_address: request.remote_ip
      })
    end
  end
end
