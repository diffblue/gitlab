# frozen_string_literal: true

module EE
  module ConfirmationsController
    extend ::Gitlab::Utils::Override
    include ::Audit::Changes

    protected

    override :after_sign_in
    def after_sign_in(resource)
      audit_changes(:email, as: 'email address', model: resource)

      super(resource)
    end
  end
end
