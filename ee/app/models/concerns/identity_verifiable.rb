# frozen_string_literal: true

module IdentityVerifiable
  include Gitlab::Utils::StrongMemoize
  extend ActiveSupport::Concern

  VERIFICATION_METHODS = {
    CREDIT_CARD: 'credit_card',
    PHONE_NUMBER: 'phone',
    EMAIL: 'email'
  }.freeze

  def identity_verified?
    email_wrapper = ::Gitlab::Email::FeatureFlagWrapper.new(email)
    return email_verified? unless Feature.enabled?(:identity_verification, email_wrapper)

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
    when 'high'
      methods.prepend VERIFICATION_METHODS[:PHONE_NUMBER] if phone_number_verification_enabled?
      methods.prepend VERIFICATION_METHODS[:CREDIT_CARD] if credit_card_verification_enabled?
    when 'medium'
      methods.prepend VERIFICATION_METHODS[:PHONE_NUMBER] if phone_number_verification_enabled?
    end

    methods
  end

  def credit_card_verified?
    credit_card_validation.present?
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

  def arkose_risk_band
    risk_band_attr = custom_attributes.by_key('arkose_risk_band').first
    return unless risk_band_attr.present?

    risk_band_attr.value.downcase
  end

  def credit_card_verification_enabled?
    Feature.enabled?(:identity_verification_credit_card)
  end

  def phone_number_verification_enabled?
    Feature.enabled?(:identity_verification_phone_number)
  end
end
