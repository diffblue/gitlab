# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::IdentityVerificationHelper do
  let_it_be(:user) { build(:user) }

  describe '#identity_verification_data' do
    before do
      allow(helper).to receive(:current_user).and_return(user)
    end

    subject(:data) { helper.identity_verification_data[:credit_card] }

    it 'returns the expected data' do
      expect(data).to eq(
        {
          completed: 'true',
          form_id: ::Gitlab::SubscriptionPortal::REGISTRATION_VALIDATION_FORM_ID
        }
      )
    end

    context 'when user is required to verify a credit card' do
      before do
        user.user_detail.update!(requires_credit_card_verification: true)
      end

      it 'returns the expected data' do
        expect(data[:completed]).to eq('false')
      end
    end
  end
end
