# frozen_string_literal: true

module EE
  module PasswordsController
    extend ActiveSupport::Concern

    prepended do
      before_action :log_audit_event, only: [:create]
    end

    private

    def log_audit_event
      ::AuditEventService.new(
        current_user,
        resource,
        action: :custom,
        custom_message: 'Ask for password reset',
        ip_address: request.remote_ip
      ).for_user(
        full_path: resource_params[:email],
        entity_id: nil
      ).unauth_security_event
    end
  end
end
