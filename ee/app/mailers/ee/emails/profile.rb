# frozen_string_literal: true

module EE
  module Emails
    module Profile
      def policy_revoked_personal_access_tokens_email(user, revoked_token_names)
        return unless user && revoked_token_names

        @user = user
        @revoked_token_names = revoked_token_names
        @target_url = profile_personal_access_tokens_url

        ::Gitlab::I18n.with_locale(@user.preferred_language) do
          mail(to: user.notification_email, subject: subject(_("One or more of you personal access tokens were revoked")))
        end
      end
    end
  end
end
