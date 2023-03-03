# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::CreateHandRaiseLeadService, feature_category: :billing_and_payments do
  let(:params) { { first_name: 'Jeremy' } }
  let(:expected_params) { params.merge(product_interaction: 'Hand Raise PQL') }

  describe '#execute' do
    before do
      expect(Gitlab::SubscriptionPortal::Client).to receive(:generate_lead).with(expected_params).and_return(response)
    end

    context 'hand raise lead call is made successfully' do
      let(:response) { { success: true } }

      it 'returns success: true' do
        result = subject.execute(params)

        expect(result.is_a?(ServiceResponse)).to be true
        expect(result.success?).to be true
      end
    end

    context 'error while creating hand raise lead call is made successful' do
      let(:response) { { success: false, data: { errors: ['some error'] } } }

      it 'returns success: false with errors' do
        result = subject.execute(params)

        expect(result.is_a?(ServiceResponse)).to be true
        expect(result.success?).to be false
        expect(result.message).to match_array(['some error'])
      end
    end
  end
end
