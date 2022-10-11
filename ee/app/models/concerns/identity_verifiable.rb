# frozen_string_literal: true

module IdentityVerifiable
  extend ActiveSupport::Concern

  VERIFICATION_METHODS = {
    CREDIT_CARD: 'credit_card',
    EMAIL: 'email'
  }.freeze

  def identity_verification_state
    # Return only the state of required verification methods instead of all
    # methods. This will save us from doing unnecessary queries. E.g. when risk
    # band is 'Low' we only need to call `confirmed?`
    required_identity_verification_methods.each_with_object({}) do |method, state|
      state[method] = verification_state[method].call
    end
  end

  def required_identity_verification_methods
    if Feature.enabled?(:identity_verification_credit_card)
      return [
        User::VERIFICATION_METHODS[:CREDIT_CARD],
        User::VERIFICATION_METHODS[:EMAIL]
      ]
    end

    [User::VERIFICATION_METHODS[:EMAIL]]
  end

  private

  def verification_state
    @verification_state ||= {
      credit_card: -> { credit_card_verified? },
      email: -> { email_verified? }
    }.stringify_keys
  end

  def credit_card_verified?
    credit_card_validation.present?
  end

  def email_verified?
    confirmed?
  end
end
