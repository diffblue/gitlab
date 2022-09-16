# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::IdentityVerificationHelper do
  let_it_be(:user) { build(:user) }

  describe '#identity_verification_data' do
    subject(:data) { helper.identity_verification_data(user) }

    it 'returns the expected data' do
      expect(data).to eq(
        {
          email: {
            obfuscated: helper.obfuscated_email(user.email),
            verify_path: verify_email_code_identity_verification_path,
            resend_path: resend_email_code_identity_verification_path
          },
          credit_card: {
            completed: 'true',
            form_id: ::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_ID
          }
        }
      )
    end

    context 'when user is required to verify a credit card' do
      before do
        user.user_detail.update!(requires_credit_card_verification: true)
      end

      it 'returns the expected data' do
        expect(data[:credit_card][:completed]).to eq('false')
      end
    end
  end
end
