# frozen_string_literal: true

module Users
  module IdentityVerificationHelper
    def identity_verification_data
      credit_card_verified = !current_user.requires_credit_card_verification

      {
        credit_card: {
          completed: credit_card_verified.to_s,
          form_id: ::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_ID
        }
      }
    end
  end
end
