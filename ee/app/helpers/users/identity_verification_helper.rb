# frozen_string_literal: true

module Users
  module IdentityVerificationHelper
    def identity_verification_data(user)
      {
        data: {
          verification_methods: user.required_identity_verification_methods,
          verification_state: user.identity_verification_state,
          credit_card: {
            user_id: user.id,
            form_id: ::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_ID
          },
          email: email_verification_data(user)
        }.to_json
      }
    end

    private

    def email_verification_data(user)
      {
        obfuscated: obfuscated_email(user.email),
        verify_path: verify_email_code_identity_verification_path,
        resend_path: resend_email_code_identity_verification_path
      }
    end
  end
end
