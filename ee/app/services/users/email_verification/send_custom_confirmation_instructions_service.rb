# frozen_string_literal: true

module Users
  module EmailVerification
    class SendCustomConfirmationInstructionsService
      include ::Gitlab::Utils::StrongMemoize

      SendConfirmationInstructionsError = Class.new(StandardError)

      def initialize(user)
        @user = user
      end

      def execute
        set_token
        send_instructions
      end

      def set_token(save: true)
        return unless enabled?

        # Don't send Devise notification, we send our own custom notification
        user.skip_confirmation_notification!

        service = ::Users::EmailVerification::GenerateTokenService.new(attr: :confirmation_token)
        @token, digest = service.execute

        user.confirmation_token = digest
        user.confirmation_sent_at = Time.current
        user.save if save
      end

      def send_instructions
        return unless enabled?

        if token.blank? || user.will_save_change_to_confirmation_token?
          raise SendConfirmationInstructionsError, 'The users confirmation token has not been set or saved'
        end

        ::Notify.confirmation_instructions_email(user.email, token: token).deliver_later
      end

      def enabled?
        self.class.enabled?(user.email)
      end
      strong_memoize_attr :enabled?

      def self.enabled?(email)
        return false if ::Feature.enabled?(:soft_email_confirmation)
        return false if ::Gitlab::CurrentSettings.require_admin_approval_after_user_signup
        return false if ::Gitlab::CurrentSettings.email_confirmation_setting_off?

        # Since we might not have a persisted user yet, we cannot scope the feature flag on the user,
        # but since we do have an email, use this wrapper that implements `flipper_id` for email addresses.
        email_wrapper = ::Gitlab::Email::FeatureFlagWrapper.new(email)
        ::Feature.enabled?(:identity_verification, email_wrapper)
      end

      private

      attr_reader :user, :token
    end
  end
end
