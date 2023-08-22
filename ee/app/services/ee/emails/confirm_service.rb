# frozen_string_literal: true

module EE
  module Emails
    module ConfirmService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(email)
        super.tap do
          log_audit_event(action: :confirm, target: email, unconfirmed_email: email.email)
        end
      end
    end
  end
end
