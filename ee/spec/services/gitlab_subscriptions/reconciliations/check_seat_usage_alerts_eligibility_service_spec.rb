# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::Reconciliations::CheckSeatUsageAlertsEligibilityService,
               :use_clean_rails_memory_store_caching, :saas, feature_category: :billing_and_payments do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let_it_be(:namespace) { create(:namespace_with_plan) }

    let(:cache_key) do
      "subscription:eligible_for_seat_usage_alerts:namespace:#{namespace.gitlab_subscription.cache_key}"
    end

    subject(:execute_service) { described_class.new(namespace: namespace).execute }

    where(:eligible_for_seat_usage_alerts, :expected_response) do
      true  | true
      false | false
    end

    with_them do
      let(:response) { { success: true, eligible_for_seat_usage_alerts: eligible_for_seat_usage_alerts } }

      before do
        allow(Gitlab::SubscriptionPortal::Client)
          .to receive(:subscription_seat_usage_alerts_eligibility)
          .and_return(response)
      end

      it 'returns the correct value' do
        expect(execute_service).to eq expected_response
      end

      it 'caches the query response' do
        expect(Rails.cache).to receive(:fetch).with(cache_key, expires_in: 1.day).and_call_original

        execute_service
      end
    end

    context 'with an unsuccessful CustomersDot query' do
      it 'assumes the subscription is ineligible' do
        allow(Gitlab::SubscriptionPortal::Client).to receive(:subscription_seat_usage_alerts_eligibility).and_return({
          success: false
        })

        expect(execute_service).to be false
      end
    end

    context 'when called with a group' do
      let(:namespace) { create(:group_with_plan) }

      it 'uses the namespace id' do
        expect(Gitlab::SubscriptionPortal::Client)
          .to receive(:subscription_seat_usage_alerts_eligibility)
          .with(namespace.id)
          .and_return({})

        execute_service
      end
    end

    context 'when the namespace has no plan' do
      let(:namespace) { build(:group) }

      it { is_expected.to be false }
    end
  end
end
