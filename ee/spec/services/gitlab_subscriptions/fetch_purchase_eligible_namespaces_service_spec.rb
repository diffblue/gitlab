# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSubscriptions::FetchPurchaseEligibleNamespacesService, feature_category: :billing_and_payments do
  describe '#execute' do
    let_it_be(:user) { build(:user) }
    let_it_be(:namespace_1) { create(:namespace) }
    let_it_be(:namespace_2) { create(:namespace) }

    context 'when no namespaces are supplied' do
      it 'returns an array with an empty hash', :aggregate_failures do
        result = described_class.new(user: user, plan_id: 'test', namespaces: []).execute

        expect(result).to be_success
        expect(result.payload).to eq []
      end
    end

    context 'when no plan_id or any_self_service_plan flag is supplied' do
      it 'logs and returns an error message', :aggregate_failures do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_and_raise_for_dev_exception)
          .with an_instance_of(ArgumentError)

        result = described_class.new(user: user, plan_id: nil, namespaces: [namespace_1]).execute

        expect(result).to be_error
        expect(result.message).to eq 'plan_id and any_self_service_plan cannot both be nil'
        expect(result.payload).to be_nil
      end
    end

    context 'when no user is supplied' do
      subject(:service) { described_class.new(user: nil, plan_id: 'test', namespaces: [namespace_1]) }

      it 'logs and returns an error message', :aggregate_failures do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_and_raise_for_dev_exception)
          .with an_instance_of(ArgumentError)

        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq 'User cannot be nil'
        expect(result.payload).to be_nil
      end
    end

    context 'when the http request fails' do
      subject(:service) { described_class.new(user: user, plan_id: 'test', namespaces: [namespace_1]) }

      before do
        allow(Gitlab::SubscriptionPortal::Client)
          .to receive(:filter_purchase_eligible_namespaces)
          .with(user, [namespace_1], plan_id: 'test', any_self_service_plan: nil)
          .and_return(success: false, data: { errors: 'error' })
      end

      it 'returns an error message', :aggregate_failures do
        result = service.execute

        expect(result).to be_error
        expect(result.message).to eq 'Failed to fetch namespaces'
        expect(result.payload).to eq 'error'
      end
    end

    context 'when all the namespaces are eligible' do
      let(:subscription_name) { 'S-000000' }

      before do
        allow(Gitlab::SubscriptionPortal::Client)
          .to receive(:filter_purchase_eligible_namespaces)
          .with(user, [namespace_1, namespace_2], plan_id: 'test', any_self_service_plan: nil)
          .and_return(
            success: true,
            data: [
              { 'id' => namespace_1.id, 'accountId' => nil, 'subscription' => { 'name' => subscription_name } },
              { 'id' => namespace_2.id, 'accountId' => nil, 'subscription' => nil }
            ])
      end

      it 'does not filter any namespaces', :aggregate_failures do
        namespaces = [namespace_1, namespace_2]
        result = described_class.new(user: user, plan_id: 'test', namespaces: namespaces).execute

        expect(result).to be_success
        expect(result.payload).to match_array [
          namespace_result(namespace_1, nil, { 'name' => subscription_name }),
          namespace_result(namespace_2, nil, nil)
        ]
      end
    end

    context 'when the user has a namespace ineligible' do
      let(:account_id) { '111111111' }

      before do
        allow(Gitlab::SubscriptionPortal::Client)
          .to receive(:filter_purchase_eligible_namespaces)
          .with(user, [namespace_1, namespace_2], plan_id: 'test', any_self_service_plan: nil)
          .and_return(success: true, data: [{ 'id' => namespace_1.id, 'accountId' => account_id }])
      end

      it 'is filtered from the results', :aggregate_failures do
        namespaces = [namespace_1, namespace_2]
        result = described_class.new(user: user, plan_id: 'test', namespaces: namespaces).execute

        expect(result).to be_success
        expect(result.payload).to match_array [
          namespace_result(namespace_1, account_id, nil)
        ]
      end
    end

    context "when supplied the any_self_service_plan flag" do
      before do
        allow(Gitlab::SubscriptionPortal::Client)
          .to receive(:filter_purchase_eligible_namespaces)
          .with(user, [namespace_1, namespace_2], plan_id: nil, any_self_service_plan: true)
          .and_return(success: true, data: [{ 'id' => namespace_1.id }])
      end

      it 'filters the results by eligibility for any self service plan' do
        namespaces = [namespace_1, namespace_2]
        result = described_class.new(user: user, namespaces: namespaces, any_self_service_plan: true).execute

        expect(result).to be_success
        expect(result.payload).to match_array [
          namespace_result(namespace_1, nil, nil)
        ]
      end
    end
  end

  private

  def namespace_result(namespace, account_id, active_subscription)
    { namespace: namespace, account_id: account_id, active_subscription: active_subscription }
  end
end
