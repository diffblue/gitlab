# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::FetchSubscriptionPlansService, feature_category: :billing_and_payments do
  describe '#execute' do
    subject(:execute_service) { described_class.new(plan: plan).execute }

    let(:endpoint_url) { ::Gitlab::Routing.url_helpers.subscription_portal_gitlab_plans_url }
    let(:plan) { 'bronze' }
    let(:response_mock) { double(body: [{ 'foo' => 'bar' }].to_json) }

    context 'when successfully fetching plans data' do
      it 'returns parsed JSON' do
        expect(Gitlab::HTTP).to receive(:get)
          .with(
            endpoint_url,
            allow_local_requests: true,
            query: { plan: plan, namespace_id: nil },
            headers: { 'Accept' => 'application/json' }
          )
          .and_return(response_mock)

        is_expected.to eq([Hashie::Mash.new('foo' => 'bar')])
      end

      it 'uses only the plan within the cache key name' do
        allow(Gitlab::HTTP).to receive(:get).and_return(response_mock)

        expect(Rails.cache).to receive(:read).with("pnp-subscription-plan-#{plan}")

        execute_service
      end

      context 'with pnp_subscription_plan_cache_key flag disabled' do
        before do
          stub_feature_flags(pnp_subscription_plan_cache_key: false, subscription_plan_cache_key: true)
        end

        it 'returns a new cache key so the cache is busted' do
          allow(Gitlab::HTTP).to receive(:get).and_return(response_mock)

          expect(Rails.cache).to receive(:read).with("subscription-plan-#{plan}")

          execute_service
        end
      end

      context 'with given namespace_id' do
        subject(:execute_service) { described_class.new(plan: plan, namespace_id: namespace_id).execute }

        let(:namespace_id) { 87 }

        it 'returns parsed JSON' do
          expect(Gitlab::HTTP).to receive(:get)
            .with(
              endpoint_url,
              allow_local_requests: true,
              query: { plan: plan, namespace_id: namespace_id },
              headers: { 'Accept' => 'application/json' }
            )
            .and_return(response_mock)

          is_expected.to eq([Hashie::Mash.new('foo' => 'bar')])
        end

        it 'uses the namespace id within the cache key name' do
          allow(Gitlab::HTTP).to receive(:get).and_return(response_mock)

          expect(Rails.cache).to receive(:read).with("pnp-subscription-plan-#{plan}-#{namespace_id}")

          execute_service
        end
      end
    end

    context 'when failing to fetch plans data' do
      before do
        expect(Gitlab::HTTP).to receive(:get).and_raise(Gitlab::HTTP::Error.new('Error message'))
      end

      it 'logs failure' do
        expect(Gitlab::AppLogger).to receive(:info).with('Unable to connect to GitLab Customers App Error message')

        execute_service
      end

      it 'returns nil' do
        is_expected.to be_nil
      end

      it 'does not cache the result' do
        service = described_class.new(plan: plan)

        Rails.cache.with_local_cache do
          service.execute

          expect(Gitlab::HTTP).to receive(:get)

          service.execute
        end
      end
    end
  end
end
