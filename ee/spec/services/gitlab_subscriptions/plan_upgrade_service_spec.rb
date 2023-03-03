# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::PlanUpgradeService, feature_category: :billing_and_payments do
  subject(:execute) { described_class.new(namespace_id: namespace_id).execute }

  let(:namespace_id) { '111' }

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    before do
      allow(Gitlab::SubscriptionPortal::Client).to receive(:plan_upgrade_offer).and_return(response)
    end

    context 'when the response is a failure' do
      let(:response) { { success: false } }

      it 'returns nil values' do
        expect(execute).to eq({
          upgrade_for_free: nil,
          upgrade_plan_id: nil
        })
      end
    end

    context 'when the response is successful' do
      where(:eligible, :assisted_id, :free_id, :plan_id) do
        true  | '111' | '222' | '111'
        true  | nil   | '222' | '222'
        true  | '111' | nil   | '111'
        true  | nil   | nil   | nil
        false | '111' | '222' | '111'
        false | '111' | nil   | '111'
        false | nil   | '222' | '222'
        nil   | '111' | '222' | nil
      end

      with_them do
        let(:response) do
          {
            success: true,
            eligible_for_free_upgrade: eligible,
            assisted_upgrade_plan_id: assisted_id,
            free_upgrade_plan_id: free_id
          }
        end

        before do
          expect(Gitlab::SubscriptionPortal::Client).to receive(:plan_upgrade_offer).once.and_return(response)
        end

        it 'returns the correct values' do
          expect(execute).to eq({
            upgrade_for_free: eligible,
            upgrade_plan_id: plan_id
          })
        end
      end
    end
  end
end
