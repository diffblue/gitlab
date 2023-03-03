# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::CheckFutureRenewalService, :use_clean_rails_memory_store_caching, :saas, feature_category: :billing_and_payments do
  using RSpec::Parameterized::TableSyntax

  describe '#execute' do
    let_it_be(:namespace) { create(:namespace_with_plan) }

    let(:cache_key) { "subscription:future_renewal:namespace:#{namespace.gitlab_subscription.cache_key}" }

    subject(:execute_service) { described_class.new(namespace: namespace).execute }

    where(:in_last_term, :expected_response) do
      true  | false
      false | true
    end

    with_them do
      let(:response) { { success: true, last_term: in_last_term } }

      before do
        allow(Gitlab::SubscriptionPortal::Client).to receive(:subscription_last_term).and_return(response)
      end

      it 'returns the correct value' do
        expect(execute_service).to eq expected_response
      end

      it 'caches the query response' do
        expect(Rails.cache).to receive(:fetch).with(cache_key, skip_nil: true, expires_in: 1.day).and_call_original

        execute_service
      end
    end

    context 'with an unsuccessful CustomersDot query' do
      it 'assumes no future renewal' do
        allow(Gitlab::SubscriptionPortal::Client).to receive(:subscription_last_term).and_return({
          success: false
        })

        expect(execute_service).to be false
      end
    end

    context 'when called with a sub-group' do
      let(:root_namespace) { create(:group_with_plan) }
      let(:namespace) { build(:group, parent: root_namespace) }

      it 'uses the root ancestor namespace' do
        expect(Gitlab::SubscriptionPortal::Client).to receive(:subscription_last_term).with(root_namespace.id).and_return({})

        execute_service
      end
    end

    context 'when the namespace has no plan' do
      let(:namespace) { build(:group) }

      it { is_expected.to be false }
    end
  end
end
