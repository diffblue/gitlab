# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::IdentityVerificationHelper, feature_category: :instance_resiliency do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:user) { create(:user) }

  describe '#identity_verification_data' do
    let(:mock_required_identity_verification_methods) { ['email'] }
    let(:mock_offer_phone_number_exemption) { true }

    let(:mock_identity_verification_state) do
      { credit_card: false, email: true }
    end

    before do
      allow(user).to receive(:required_identity_verification_methods).and_return(
        mock_required_identity_verification_methods
      )
      allow(user).to receive(:identity_verification_state).and_return(
        mock_identity_verification_state
      )
      allow(user).to receive(:offer_phone_number_exemption?).and_return(
        mock_offer_phone_number_exemption
      )
    end

    subject(:data) { helper.identity_verification_data(user) }

    context 'when no phone number for user exists' do
      it 'returns the expected data' do
        expect(data[:data]).to eq(expected_data.to_json)
      end
    end

    context 'when phone number for user exists' do
      let_it_be(:phone_number_validation) { create(:phone_number_validation, user: user) }

      it 'returns the expected data with saved phone number' do
        phone_number_data = expected_data[:phone_number].merge({
          country: phone_number_validation.country,
          international_dial_code: phone_number_validation.international_dial_code,
          number: phone_number_validation.phone_number
        })

        expect(data[:data]).to eq(expected_data.merge({ phone_number: phone_number_data }).to_json)
      end
    end

    describe 'has_medium_or_high_risk_band?' do
      subject(:has_medium_or_high_risk_band?) { helper.has_medium_or_high_risk_band?(user) }

      where(:risk, :expectation) do
        Arkose::VerifyResponse::RISK_BAND_HIGH   | true
        Arkose::VerifyResponse::RISK_BAND_MEDIUM | true
        Arkose::VerifyResponse::RISK_BAND_LOW    | false
      end

      with_them do
        before do
          create(:user_custom_attribute, key: UserCustomAttribute::ARKOSE_RISK_BAND, value: risk.downcase,
            user_id: user.id)
        end

        it { is_expected.to be expectation }
      end
    end

    describe '#rate_limited_error_message' do
      subject(:message) { helper.rate_limited_error_message(limit) }

      let(:limit) { :credit_card_verification_check_for_reuse }

      it 'returns a generic error message' do
        expect(message).to eq(format(s_("IdentityVerification|You've reached the maximum amount of tries. " \
                                        'Wait %{interval} and try again.'), { interval: 'about 1 hour' }))
      end

      context 'when the limit is for email_verification_code_send' do
        let(:limit) { :email_verification_code_send }

        it 'returns a specific message' do
          expect(message).to eq(format(s_("IdentityVerification|You've reached the maximum amount of resends. " \
                                          'Wait %{interval} and try again.'), { interval: 'about 1 hour' }))
        end
      end
    end

    private

    def expected_data
      {
        verification_methods: mock_required_identity_verification_methods,
        verification_state: mock_identity_verification_state,
        offer_phone_number_exemption: mock_offer_phone_number_exemption,
        phone_exemption_path: toggle_phone_exemption_identity_verification_path,
        credit_card: {
          user_id: user.id,
          form_id: ::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_ID,
          verify_credit_card_path: verify_credit_card_identity_verification_path
        },
        phone_number: {
          send_code_path: send_phone_verification_code_identity_verification_path,
          verify_code_path: verify_phone_verification_code_identity_verification_path
        },
        email: {
          obfuscated: helper.obfuscated_email(user.email),
          verify_path: verify_email_code_identity_verification_path,
          resend_path: resend_email_code_identity_verification_path
        },
        successful_verification_path: success_identity_verification_path
      }
    end
  end

  describe '#user_banned_error_message' do
    subject(:user_banned_error_message) { helper.user_banned_error_message }

    where(:dot_com, :error_message) do
      true  | "Your account has been blocked. Contact #{EE::CUSTOMER_SUPPORT_URL} for assistance."
      false | "Your account has been blocked. Contact your GitLab administrator for assistance."
    end

    with_them do
      before do
        allow(Gitlab).to receive(:com?).and_return(dot_com)
      end

      it 'returns the correct account banned error message' do
        expect(user_banned_error_message).to eq(error_message)
      end
    end
  end
end
