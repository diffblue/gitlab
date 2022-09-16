# frozen_string_literal: true

module Users
  module IdentityVerificationHelper
    def identity_verification_data(user)
      credit_card_verified = !user.requires_credit_card_verification
      {
        email: {
          obfuscated: obfuscated_email(user.email),
          verify_path: verify_email_code_identity_verification_path,
          resend_path: resend_email_code_identity_verification_path
        },
        credit_card: {
          completed: credit_card_verified.to_s,
          form_id: ::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_ID
        }
      }
    end
  end
end
