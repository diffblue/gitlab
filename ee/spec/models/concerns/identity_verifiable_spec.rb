# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdentityVerifiable do
  let_it_be(:user) { create(:user) }

  describe('#required_identity_verification_methods') do
    subject { user.required_identity_verification_methods }

    it { is_expected.to eq %w[credit_card email] }

    context 'when identity_verification_credit_card is disabled' do
      before do
        stub_feature_flags(identity_verification_credit_card: false)
      end

      it { is_expected.to eq %w[email] }
    end
  end

  describe('#identity_verification_state') do
    let(:state) { user.identity_verification_state }

    describe 'credit card verification state' do
      subject { state['credit_card'] }

      context 'when user has not verified a credit card' do
        it { is_expected.to eq false }
      end

      context 'when user has verified a credit card' do
        let!(:credit_card_validation) { create(:credit_card_validation, user: user) }

        it { is_expected.to eq true }
      end
    end

    describe 'email verification state' do
      subject { state['email'] }

      context 'when user has not verified their email' do
        before do
          allow(user).to receive(:confirmed?).and_return(false)
        end

        it { is_expected.to eq false }
      end

      context 'when user has verified their email' do
        before do
          allow(user).to receive(:confirmed?).and_return(true)
        end

        it { is_expected.to eq true }
      end
    end
  end
end
