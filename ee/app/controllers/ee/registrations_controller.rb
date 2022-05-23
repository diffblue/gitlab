# frozen_string_literal: true

module EE
  module RegistrationsController
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      before_action :ensure_can_remove_self, only: [:destroy]
    end

    private

    override :after_request_hook
    def after_request_hook(user)
      super

      log_audit_event(user)
    end

    override :set_blocked_pending_approval?
    def set_blocked_pending_approval?
      super || ::Gitlab::CurrentSettings.should_apply_user_signup_cap?
    end

    def ensure_can_remove_self
      unless current_user&.can_remove_self?
        redirect_to profile_account_path,
                    status: :see_other,
                    alert: s_('Profiles|Account could not be deleted. GitLab was unable to verify your identity.')
      end
    end

    def log_audit_event(user)
      return unless user&.persisted?

      ::AuditEventService.new(
        user,
        user,
        action: :custom,
        custom_message: _('Instance access request')
      ).for_user.security_event
    end
  end
end
