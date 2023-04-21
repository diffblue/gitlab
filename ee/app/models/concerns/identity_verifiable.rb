# frozen_string_literal: true

module IdentityVerifiable
  include Gitlab::Utils::StrongMemoize
  extend ActiveSupport::Concern

  VERIFICATION_METHODS = {
    CREDIT_CARD: 'credit_card',
    PHONE_NUMBER: 'phone',
    EMAIL: 'email'
  }.freeze

  def identity_verification_enabled?
    return false unless ::Gitlab::CurrentSettings.email_confirmation_setting_hard?
    return false if ::Gitlab::CurrentSettings.require_admin_approval_after_user_signup

    email_wrapper = ::Gitlab::Email::FeatureFlagWrapper.new(email)
    Feature.enabled?(:identity_verification, email_wrapper)
  end

  def active_for_authentication?
    return false unless super

    !identity_verification_enabled? || identity_verified?
  end

  def identity_verified?
    return email_verified? unless identity_verification_enabled?

    # Treat users that have already signed in before as verified if their email
    # is already verified.
    #
    # This prevents the scenario where a user has to verify their identity
    # multiple times. For example:
    #
    # 1. identity_verification FF is enabled while
    # identity_verification_credit_card is disabled
    # 2. A user registers, is assigned High risk band, verifies their email as
    # prompted, and starts using GitLab
    # 3. identity_verification_credit_card FF is enabled
    # 4. User signs out and signs in again
    # 5. User is redirected to Identity Verification which requires them to
    # verify their credit card
    return email_verified? if last_sign_in_at.present?

    identity_verification_state.values.all?
  end

  def identity_verification_state
    # Return only the state of required verification methods instead of all
    # methods. This will save us from doing unnecessary queries. E.g. when risk
    # band is 'Low' we only need to call `confirmed?`
    required_identity_verification_methods.index_with do |method|
      verification_state[method].call
    end
  end
  strong_memoize_attr :identity_verification_state

  def required_identity_verification_methods
    methods = [VERIFICATION_METHODS[:EMAIL]]

    case arkose_risk_band
    when Arkose::VerifyResponse::RISK_BAND_HIGH.downcase
      methods.prepend VERIFICATION_METHODS[:PHONE_NUMBER] if phone_number_verification_enabled?
      methods.prepend VERIFICATION_METHODS[:CREDIT_CARD] if credit_card_verification_enabled?
    when Arkose::VerifyResponse::RISK_BAND_MEDIUM.downcase
      methods.prepend VERIFICATION_METHODS[:PHONE_NUMBER] if phone_number_verification_enabled?
    end

    methods
  end

  def credit_card_verified?
    credit_card_validation.present?
  end

  def arkose_risk_band
    risk_band_attr = custom_attributes.by_key(UserCustomAttribute::ARKOSE_RISK_BAND).first
    return unless risk_band_attr.present?

    risk_band_attr.value.downcase
  end

  private

  def verification_state
    @verification_state ||= {
      credit_card: -> { credit_card_verified? },
      phone: -> { phone_verified? },
      email: -> { email_verified? }
    }.stringify_keys
  end

  def phone_verified?
    phone_number_validation.present? && phone_number_validation.validated?
  end

  def email_verified?
    confirmed?
  end

  def credit_card_verification_enabled?
    return false unless is_a?(User)

    Feature.enabled?(:identity_verification_credit_card, self)
  end

  def phone_number_verification_enabled?
    return false unless is_a?(User)

    Feature.enabled?(:identity_verification_phone_number, self)
  end
end
