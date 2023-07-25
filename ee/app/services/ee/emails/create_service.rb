# frozen_string_literal: true

module EE
  module Emails
    module CreateService
      extend ::Gitlab::Utils::Override

      override :execute
      def execute(extra_params = {})
        super.tap do |email|
          log_audit_event(action: :create, target: email) if email.persisted?
        end
      end
    end
  end
end
