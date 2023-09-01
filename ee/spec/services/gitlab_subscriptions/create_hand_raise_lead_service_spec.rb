# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::CreateHandRaiseLeadService, feature_category: :billing_and_payments do
  describe '#execute' do
    let(:params) { { first_name: 'Jeremy', product_interaction: 'Hand Raise PQL' } }

    subject(:execute) { described_class.new.execute(params) }

    context 'when hand raise lead call is made successfully' do
      let(:response) { { success: true } }

      it 'returns success: true' do
        expect(Gitlab::SubscriptionPortal::Client).to receive(:generate_lead).with(params).and_return(response)

        result = execute

        expect(result.is_a?(ServiceResponse)).to be true
        expect(result.success?).to be true
      end
    end

    context 'with an error while creating hand raise lead call is made successful' do
      let(:response) { { success: false, data: { errors: ['some error'] } } }

      it 'returns success: false with errors' do
        expect(Gitlab::SubscriptionPortal::Client).to receive(:generate_lead).with(params).and_return(response)

        result = execute

        expect(result.is_a?(ServiceResponse)).to be true
        expect(result.success?).to be false
        expect(result.message).to match_array(['some error'])
      end
    end
  end
end
