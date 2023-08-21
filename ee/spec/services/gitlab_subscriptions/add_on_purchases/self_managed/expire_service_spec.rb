# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::AddOnPurchases::SelfManaged::ExpireService, :aggregate_failures, feature_category: :sm_provisioning do
  describe '#execute' do
    let_it_be(:add_on_purchase) { create(:gitlab_subscription_add_on_purchase) }

    subject(:result) { described_class.new(add_on_purchase).execute }

    context 'when update fails' do
      before do
        allow(add_on_purchase).to receive(:update).and_return(false)
      end

      it 'returns an error' do
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Add-on purchase could not be saved')
        expect(result[:add_on_purchase]).to be_an_instance_of(GitlabSubscriptions::AddOnPurchase)
      end
    end

    it 'updates the expiration date' do
      expect do
        result
        add_on_purchase.reload
      end.to change { add_on_purchase.expires_on }.to(Date.yesterday)

      expect(result[:status]).to eq(:success)
      expect(result[:add_on_purchase]).to eq(nil)
    end
  end
end
