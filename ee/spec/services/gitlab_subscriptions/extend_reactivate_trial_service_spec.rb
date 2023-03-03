# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::ExtendReactivateTrialService, feature_category: :billing_and_payments do
  subject(:execute) { described_class.new.execute(extend_reactivate_trial_params) }

  let_it_be(:namespace) { create(:namespace) }

  let(:extend_reactivate_trial_params) do
    {
      trial_user: {
        namespace_id: namespace.id,
        trial_extension_type: GitlabSubscription.trial_extension_types[:extended]
      }
    }
  end

  describe '#execute' do
    before do
      allow(Gitlab::SubscriptionPortal::Client).to receive(:extend_reactivate_trial).and_return(response)
    end

    context 'trial is extended/reactivated successfully' do
      let(:response) { { success: true } }

      it 'returns success: true' do
        result = execute

        expect(result.is_a?(ServiceResponse)).to be true
        expect(result.success?).to be true
      end
    end

    context 'error while extending/reactivating the trial' do
      let(:response) { { success: false, data: { errors: ['some error'] } } }

      it 'returns success: false with errors' do
        result = execute

        expect(result.is_a?(ServiceResponse)).to be true
        expect(result.success?).to be false
        expect(result.message).to eq(['some error'])
      end
    end
  end
end
