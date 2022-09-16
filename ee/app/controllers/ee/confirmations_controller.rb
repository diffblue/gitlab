# frozen_string_literal: true

module EE
  module ConfirmationsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override
    include ::Audit::Changes

    prepended do
      before_action :custom_confirmation_enabled, only: :create
    end

    protected

    override :after_sign_in
    def after_sign_in(resource)
      audit_changes(:email, as: 'email address', model: resource)

      super(resource)
    end

    private

    def custom_confirmation_enabled
      # Prevent generating a new confirmation token and sending the Devise confirmation
      # instructions when custom confirmation is enabled.
      email_wrapper = ::Gitlab::Email::FeatureFlagWrapper.new(resource_params[:email])
      not_found if ::Feature.enabled?(:identity_verification, email_wrapper)
    end
  end
end
