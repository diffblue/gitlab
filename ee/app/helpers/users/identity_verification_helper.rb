# frozen_string_literal: true

module Users
  module IdentityVerificationHelper
    def identity_verification_data(user)
      {
        data: {
          verification_methods: user.required_identity_verification_methods,
          verification_state: user.identity_verification_state,
          offer_phone_number_exemption: user.offer_phone_number_exemption?,
          phone_exemption_path: toggle_phone_exemption_identity_verification_path,
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

    def user_banned_error_message
      if ::Gitlab.com?
        format(
          _("Your account has been blocked. Contact %{support} for assistance."),
          support: EE::CUSTOMER_SUPPORT_URL
        )
      else
        _("Your account has been blocked. Contact your GitLab administrator for assistance.")
      end
    end

    def has_medium_or_high_risk_band?(user)
      user.arkose_risk_band.in?([
        Arkose::VerifyResponse::RISK_BAND_HIGH.downcase,
        Arkose::VerifyResponse::RISK_BAND_MEDIUM.downcase
      ])
    end

    def rate_limited_error_message(limit)
      interval_in_seconds = ::Gitlab::ApplicationRateLimiter.rate_limits[limit][:interval]
      interval = distance_of_time_in_words(interval_in_seconds)
      message = if limit == :email_verification_code_send
                  s_("IdentityVerification|You've reached the maximum amount of resends. " \
                     'Wait %{interval} and try again.')
                else
                  s_("IdentityVerification|You've reached the maximum amount of tries. " \
                     'Wait %{interval} and try again.')
                end

      format(message, interval: interval)
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
