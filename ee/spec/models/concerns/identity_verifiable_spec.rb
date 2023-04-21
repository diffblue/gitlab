# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdentityVerifiable, feature_category: :instance_resiliency do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:user) { create(:user) }

  def add_user_risk_band(value)
    create(:user_custom_attribute, key: UserCustomAttribute::ARKOSE_RISK_BAND, value: value, user_id: user.id)
  end

  describe('#identity_verification_enabled?') do
    where(
      identity_verification: [true, false],
      require_admin_approval_after_user_signup: [true, false],
      email_confirmation_setting: %w[soft hard off]
    )

    with_them do
      before do
        stub_feature_flags(identity_verification: identity_verification)
        stub_application_setting(require_admin_approval_after_user_signup: require_admin_approval_after_user_signup)
        stub_application_setting_enum('email_confirmation_setting', email_confirmation_setting)
      end

      it 'returns the expected result' do
        result = identity_verification &&
          !require_admin_approval_after_user_signup &&
          email_confirmation_setting == 'hard'

        expect(user.identity_verification_enabled?).to eq(result)
      end
    end
  end

  describe('#active_for_authentication?') do
    subject { user.active_for_authentication? }

    where(:identity_verification_enabled?, :identity_verified?, :result) do
      true  | true  | true
      true  | false | false
      false | true  | true
      false | false | true
    end

    before do
      allow(user).to receive(:identity_verification_enabled?).and_return(identity_verification_enabled?)
      allow(user).to receive(:identity_verified?).and_return(identity_verified?)
    end

    with_them do
      context 'when not confirmed' do
        before do
          allow(user).to receive(:confirmed?).and_return(false)
        end

        it { is_expected.to eq(false) }
      end

      context 'when confirmed' do
        before do
          allow(user).to receive(:confirmed?).and_return(true)
        end

        it { is_expected.to eq(result) }
      end
    end
  end

  describe('#identity_verified?') do
    subject { user.identity_verified? }

    where(:phone_verified, :email_verified, :result) do
      true  | true  | true
      true  | false | false
      false | true  | false
      false | false | false
    end

    with_them do
      before do
        allow(user).to receive(:identity_verification_enabled?).and_return(true)
        allow(user).to receive(:identity_verification_state).and_return(
          {
            phone: phone_verified,
            email: email_verified
          }
        )
      end

      it { is_expected.to eq(result) }
    end

    context 'when identity verification is not enabled' do
      before do
        allow(user).to receive(:identity_verification_enabled?).and_return(false)
      end

      context 'and their email is already verified' do
        it { is_expected.to eq(true) }
      end

      context 'and their email is not yet verified' do
        let(:user) { create(:user, :unconfirmed) }

        it { is_expected.to eq(false) }
      end
    end

    context 'when user has already signed in before' do
      context 'and their email is already verified' do
        let(:user) { create(:user, last_sign_in_at: Time.zone.now) }

        it { is_expected.to eq(true) }
      end

      context 'and their email is not yet verified' do
        let(:user) { create(:user, :unconfirmed, last_sign_in_at: Time.zone.now) }

        it { is_expected.to eq(false) }
      end
    end
  end

  describe('#required_identity_verification_methods') do
    subject { user.required_identity_verification_methods }

    where(:risk_band, :credit_card, :phone_number, :result) do
      'High'   | true  | true  | %w[credit_card phone email]
      'High'   | false | true  | %w[phone email]
      'High'   | true  | false | %w[credit_card email]
      'High'   | false | false | %w[email]
      'Medium' | true  | true  | %w[phone email]
      'Medium' | false | true  | %w[phone email]
      'Medium' | true  | false | %w[email]
      'Medium' | false | false | %w[email]
      'Low'    | true  | true  | %w[email]
      'Low'    | false | true  | %w[email]
      'Low'    | true  | false | %w[email]
      'Low'    | false | false | %w[email]
      nil      | true  | true  | %w[email]
      nil      | false | true  | %w[email]
      nil      | true  | false | %w[email]
      nil      | false | false | %w[email]
    end

    with_them do
      before do
        add_user_risk_band(risk_band) if risk_band

        stub_feature_flags(identity_verification_credit_card: credit_card)
        stub_feature_flags(identity_verification_phone_number: phone_number)
      end

      it { is_expected.to eq(result) }
    end

    context 'when flag is enabled for a specific user' do
      let_it_be(:another_user) { create(:user) }

      where(:risk_band, :credit_card, :phone_number, :result) do
        'High'   | true  | false | %w[credit_card email]
        'Medium' | false | true  | %w[phone email]
      end

      with_them do
        before do
          stub_feature_flags(
            identity_verification_phone_number: false,
            identity_verification_credit_card: false
          )

          add_user_risk_band(risk_band)
          create(:user_custom_attribute, key: UserCustomAttribute::ARKOSE_RISK_BAND, value: risk_band,
            user: another_user)

          stub_feature_flags(identity_verification_phone_number: user) if phone_number
          stub_feature_flags(identity_verification_credit_card: user) if credit_card
        end

        it 'only affects that user' do
          expect(user.required_identity_verification_methods).to eq(result)
          expect(another_user.required_identity_verification_methods).to eq(%w[email])
        end
      end
    end
  end

  describe('#identity_verification_state') do
    describe 'credit card verification state' do
      before do
        add_user_risk_band('High')
      end

      subject { user.identity_verification_state['credit_card'] }

      context 'when user has not verified a credit card' do
        let(:user) { create(:user, credit_card_validation: nil) }

        it { is_expected.to eq false }
      end

      context 'when user has verified a credit card' do
        let(:validation) { create(:credit_card_validation) }
        let(:user) { create(:user, credit_card_validation: validation) }

        it { is_expected.to eq true }
      end
    end

    describe 'phone verification state' do
      before do
        add_user_risk_band('Medium')
      end

      subject { user.identity_verification_state['phone'] }

      context 'when user has no phone number' do
        let(:user) { create(:user, phone_number_validation: nil) }

        it { is_expected.to eq false }
      end

      context 'when user has not verified a phone number' do
        let(:validation) { create(:phone_number_validation) }
        let(:user) { create(:user, phone_number_validation: validation) }

        before do
          allow(validation).to receive(:validated?).and_return(false)
        end

        it { is_expected.to eq false }
      end

      context 'when user has verified a phone number' do
        let(:validation) { create(:phone_number_validation) }
        let(:user) { create(:user, phone_number_validation: validation) }

        before do
          allow(validation).to receive(:validated?).and_return(true)
        end

        it { is_expected.to eq true }
      end
    end

    describe 'email verification state' do
      subject { user.identity_verification_state['email'] }

      context 'when user has not verified their email' do
        let(:user) { create(:user, :unconfirmed) }

        it { is_expected.to eq false }
      end

      context 'when user has verified their email' do
        let(:user) { create(:user) }

        it { is_expected.to eq true }
      end
    end
  end

  describe('#credit_card_verified?') do
    subject { user.credit_card_verified? }

    context 'when user has not verified a credit card' do
      it { is_expected.to eq false }
    end

    context 'when user has verified a credit card' do
      let!(:credit_card_validation) { create(:credit_card_validation, user: user) }

      it { is_expected.to eq true }
    end
  end

  describe('#arkose_risk_band') do
    subject { user.arkose_risk_band }

    context 'when user does not have an arkose labs risk band' do
      it { is_expected.to be_nil }
    end

    context 'when user has an arkose labs risk band' do
      before do
        add_user_risk_band('High')
      end

      it { is_expected.to eq 'high' }
    end
  end
end
