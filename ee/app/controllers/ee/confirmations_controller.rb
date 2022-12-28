# frozen_string_literal: true

module EE
  module ConfirmationsController
    extend ::Gitlab::Utils::Override
    include ::Audit::Changes

    protected

    override :after_sign_in
    def after_sign_in(resource)
      audit_changes(:email, as: 'email address', model: resource, event_type: 'user_email_changed_and_user_signed_in')

      super(resource)
    end
  end
end
