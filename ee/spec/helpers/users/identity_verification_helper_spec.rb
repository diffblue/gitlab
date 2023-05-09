# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::IdentityVerificationHelper do
  let_it_be_with_reload(:user) { create(:user) }

  describe '#identity_verification_data' do
    let(:mock_required_identity_verification_methods) { ['email'] }

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

    private

    def expected_data
      {
        verification_methods: mock_required_identity_verification_methods,
        verification_state: mock_identity_verification_state,
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
end
