# frozen_string_literal: true

module Audit
  class UserPasswordResetAuditor < BaseChangesAuditor
    def initialize(current_user, model, remote_ip)
      super(current_user, model)

      @remote_ip = remote_ip
    end

    def audit_reset_failure
      errors = @model.errors[:password]
      return if errors.blank?

      ::Gitlab::Audit::Auditor.audit({
        name: "password_reset_failed",
        author: @current_user,
        scope: @model,
        target: @model,
        target_details: @current_user.email,
        message: failure_message(errors),
        ip_address: @remote_ip
      })
    end

    private

    def failure_message(errors)
      "Password reset failed with reason#{errors.count > 1 ? 's' : nil}: #{errors.to_sentence}"
    end
  end
end
