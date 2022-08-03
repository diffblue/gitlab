# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::ApplyTrialService do
  subject(:execute) { described_class.new.execute(apply_trial_params) }

  let_it_be(:namespace) { create(:namespace) }

  let(:apply_trial_params) do
    {
      trial_user: {
        namespace_id: namespace.id
      }
    }
  end

  describe '#execute' do
    before do
      allow(Gitlab::SubscriptionPortal::Client).to receive(:generate_trial).and_return(response)
    end

    context 'trial applied successfully' do
      let(:response) { { success: true } }

      it 'returns success: true' do
        expect(execute).to eq({ success: true })
      end

      it_behaves_like 'records an onboarding progress action', :trial_started
    end

    context 'error while applying the trial' do
      let(:response) { { success: false, data: { errors: ['some error'] } } }

      it 'returns success: false with errors' do
        expected_response = {
          success: false,
          errors: ['some error']
        }

        expect(execute).to eq(expected_response)
      end

      it_behaves_like 'does not record an onboarding progress action'
    end
  end
end
