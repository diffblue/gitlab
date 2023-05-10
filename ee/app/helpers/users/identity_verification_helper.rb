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
            form_id: ::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_ID,
            verify_credit_card_path: verify_credit_card_identity_verification_path
          },
          phone_number: phone_number_verification_data(user),
          email: email_verification_data(user),
          successful_verification_path: success_identity_verification_path
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

    def phone_number_verification_data(user)
      paths = {
        send_code_path: send_phone_verification_code_identity_verification_path,
        verify_code_path: verify_phone_verification_code_identity_verification_path
      }

      phone_number_validation = user.phone_number_validation
      return paths unless phone_number_validation.present?

      paths.merge(
        {
          country: phone_number_validation.country,
          international_dial_code: phone_number_validation.international_dial_code,
          number: phone_number_validation.phone_number
        }
      )
    end
  end
end
