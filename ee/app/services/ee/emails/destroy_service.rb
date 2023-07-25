# frozen_string_literal: true

module EE
  module Emails
    module DestroyService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(email)
        super.tap do
          log_audit_event(action: :destroy, target: email)
        end
      end
    end
  end
end
