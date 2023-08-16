# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdentityVerifiable, feature_category: :instance_resiliency do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:user) { create(:user) }

  def add_user_risk_band(value)
    create(:user_custom_attribute, key: UserCustomAttribute::ARKOSE_RISK_BAND, value: value, user_id: user.id)
  end

  def add_phone_exemption
    create(:user_custom_attribute, key: UserCustomAttribute::IDENTITY_VERIFICATION_PHONE_EXEMPT, value: true.to_s,
      user_id: user.id)
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

    where(:identity_verification_enabled?, :identity_verified?, :email_confirmation_setting, :result) do
      true  | true  | 'hard' | true
      true  | false | 'hard' | false
      false | false | 'hard' | true
      false | true  | 'hard' | true
      true  | true  | 'soft' | true
      true  | false | 'soft' | false
      false | false | 'soft' | true
      false | true  | 'soft' | true
    end

    before do
      allow(user).to receive(:identity_verification_enabled?).and_return(identity_verification_enabled?)
      allow(user).to receive(:identity_verified?).and_return(identity_verified?)
      stub_application_setting_enum('email_confirmation_setting', email_confirmation_setting)
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

    let(:user) { create(:user) }

    where(:risk_band, :credit_card, :phone_number, :phone_exempt, :result) do
      'High'   | true  | true  | false | %w[credit_card phone email]
      'High'   | true  | true  | true  | %w[credit_card email]
      'High'   | false | true  | false | %w[phone email]
      'High'   | true  | false | false | %w[credit_card email]
      'High'   | false | false | false | %w[email]
      'Medium' | true  | true  | false | %w[phone email]
      'Medium' | false | true  | false | %w[phone email]
      'Medium' | true  | true  | true  | %w[credit_card email]
      'Medium' | true  | false | false | %w[email]
      'Medium' | false | false | false | %w[email]
      'Low'    | true  | true  | false | %w[email]
      'Low'    | false | true  | false | %w[email]
      'Low'    | true  | false | false | %w[email]
      'Low'    | false | false | false | %w[email]
      nil      | true  | true  | false | %w[email]
      nil      | false | true  | false | %w[email]
      nil      | true  | false | false | %w[email]
      nil      | false | false | false | %w[email]
    end

    with_them do
      before do
        add_user_risk_band(risk_band) if risk_band
        add_phone_exemption if phone_exempt

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

    describe 'phone_verification_for_low_risk_users experiment', :experiment do
      let(:user) { create(:user) }
      let(:experiment_instance) { experiment(:phone_verification_for_low_risk_users) }

      before do
        add_user_risk_band('Low')
      end

      subject(:verification_methods) { user.required_identity_verification_methods }

      context 'when the user is in the control group' do
        before do
          stub_experiments(phone_verification_for_low_risk_users: :control)
        end

        it { is_expected.to eq(%w[email]) }

        it 'tracks control group assignment for the user' do
          expect(experiment_instance).to track(:assignment).on_next_instance.with_context(user: user).for(:control)

          verification_methods
        end
      end

      context 'when the user is in the candidate group' do
        before do
          stub_experiments(phone_verification_for_low_risk_users: :candidate)
        end

        it { is_expected.to eq(%w[phone email]) }

        it 'tracks candidate group assignment for the user' do
          expect(experiment_instance).to track(:assignment).on_next_instance.with_context(user: user).for(:candidate)

          verification_methods
        end
      end

      context 'when the experiment is disabled' do
        before do
          stub_experiments(phone_verification_for_low_risk_users: false)
        end

        it { is_expected.to eq(%w[email]) }

        it 'does not track assignment' do
          expect(experiment_instance).not_to track(:assignment).on_next_instance

          verification_methods
        end
      end

      context 'when phone verification is disabled' do
        before do
          stub_experiments(phone_verification_for_low_risk_users: :candidate)
          stub_feature_flags(identity_verification_phone_number: false)
        end

        it { is_expected.to eq(%w[email]) }

        it 'does not track assignment' do
          expect(experiment_instance).not_to track(:assignment).on_next_instance

          verification_methods
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

      context 'when credit card has been used by a banned user' do
        before do
          allow(credit_card_validation).to receive(:used_by_banned_user?).and_return(true)
        end

        it { is_expected.to eq false }
      end
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

  describe '#exempt_from_phone_number_verification?' do
    subject(:phone_number_exemption_attribute) { user.exempt_from_phone_number_verification? }

    let(:user) { create(:user) }

    context 'when a user has a phone number exemption' do
      before do
        add_phone_exemption
      end

      it { is_expected.to be true }
    end

    context 'when a user does not have an exemption' do
      it { is_expected.to be false }
    end
  end

  describe '#create_phone_number_exemption!' do
    subject(:create_phone_number_exemption) { user.create_phone_number_exemption! }

    let(:user) { create(:user) }

    it 'creates an exemption' do
      expect { subject }.to change {
        user.custom_attributes.by_key(UserCustomAttribute::IDENTITY_VERIFICATION_PHONE_EXEMPT).count
      }.from(0).to(1)
    end
  end

  describe '#destroy_phone_number_exemption' do
    subject(:destroy_phone_number_exemption) { user.destroy_phone_number_exemption }

    let(:user) { create(:user) }

    context 'when a user has a phone number exemption' do
      before do
        add_phone_exemption
      end

      it 'destroys the exemption' do
        subject

        expect(user.custom_attributes.by_key(UserCustomAttribute::IDENTITY_VERIFICATION_PHONE_EXEMPT)).to be_empty
      end
    end

    context 'when a user does not have a phone number exemption' do
      it { is_expected.to be false }
    end
  end

  describe '#toggle_phone_number_verification' do
    subject(:toggle_phone_number_verification) { user.toggle_phone_number_verification }

    context 'when not exempt from phone number verification' do
      it 'creates an exemption' do
        expect(user).to receive(:create_phone_number_exemption!)

        toggle_phone_number_verification
      end
    end

    context 'when exempt from phone number verification' do
      before do
        user.create_phone_number_exemption!
      end

      it 'destroys the exemption' do
        expect(user).to receive(:destroy_phone_number_exemption)

        toggle_phone_number_verification
      end
    end

    it 'clears memoization of phone_number_exemption_attribute and identity_verification_state', :aggregate_failures do
      expect(user).to receive(:clear_memoization).with(:phone_number_exemption_attribute).and_call_original
      expect(user).to receive(:clear_memoization).with(:identity_verification_state).and_call_original

      toggle_phone_number_verification
    end
  end

  describe '#offer_phone_number_exemption?' do
    subject(:offer_phone_number_exemption?) { !!user.offer_phone_number_exemption? }

    where(:credit_card, :risk_band, :phone_number, :experiment_group, :result) do
      true  | 'Low'         | true  | :candidate | true
      true  | 'Low'         | true  | :control   | false
      true  | 'Low'         | false | :candidate | false
      true  | 'Low'         | false | :control   | false
      true  | 'Medium'      | true  | :candidate | true
      true  | 'Medium'      | true  | :control   | true
      true  | 'Medium'      | false | :candidate | true
      true  | 'Medium'      | false | :control   | true
      true  | 'High'        | true  | :control   | false
      true  | 'Unavailable' | true  | :control   | false
      true  | nil           | true  | :control   | false
      false | 'Low'         | true  | :candidate | false
      false | 'Low'         | true  | :control   | false
      false | 'Low'         | false | :candidate | false
      false | 'Low'         | false | :control   | false
      false | 'Medium'      | true  | :candidate | false
      false | 'Medium'      | true  | :control   | false
      false | 'Medium'      | false | :candidate | false
      false | 'Medium'      | false | :control   | false
      false | 'High'        | true  | :control   | false
      false | 'Unavailable' | true  | :control   | false
      false | nil           | true  | :control   | false
    end

    with_them do
      before do
        add_user_risk_band(risk_band) if risk_band
        stub_feature_flags(identity_verification_credit_card: credit_card)
        stub_feature_flags(identity_verification_phone_number: phone_number)
        stub_experiments(phone_verification_for_low_risk_users: experiment_group)
      end

      it { is_expected.to eq(result) }
    end
  end
end
