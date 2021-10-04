# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::CreateHandRaiseLeadService do
  subject(:execute) { described_class.new.execute(params) }

  let(:params) { {} }

  describe '#execute' do
    before do
      allow(Gitlab::SubscriptionPortal::Client).to receive(:generate_hand_raise_lead).with(params).and_return(response)
    end

    context 'hand raise lead call is made successfully' do
      let(:response) { { success: true } }

      it 'returns success: true' do
        result = execute

        expect(result.is_a?(ServiceResponse)).to be true
        expect(result.success?).to be true
      end
    end

    context 'error while creating hand raise lead call is made successful' do
      let(:response) { { success: false, data: { errors: ['some error'] } } }

      it 'returns success: false with errors' do
        result = execute

        expect(result.is_a?(ServiceResponse)).to be true
        expect(result.success?).to be false
        expect(result.message).to match_array(['some error'])
      end
    end
  end
end
