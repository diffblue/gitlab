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

        service = ::Users::EmailVerification::GenerateTokenService.new(attr: :confirmation_token, user: user)
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

      private

      def enabled?
        !user.confirmed? && user.identity_verification_enabled?
      end
      strong_memoize_attr :enabled?

      attr_reader :user, :token
    end
  end
end
