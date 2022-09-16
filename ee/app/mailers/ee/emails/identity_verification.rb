# frozen_string_literal: true

module EE
  module Emails
    module IdentityVerification
      def confirmation_instructions_email(email, token:)
        @token = token
        @expires_in_minutes = ::Users::EmailVerification::ValidateTokenService::TOKEN_VALID_FOR_MINUTES

        email_with_layout(to: email, subject: s_('IdentityVerification|Confirm your email address'))
      end
    end
  end
end
