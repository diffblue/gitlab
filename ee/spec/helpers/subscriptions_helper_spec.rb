# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SubscriptionsHelper do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:free_plan) do
    { "name" => "Free Plan", "free" => true, "code" => "free" }
  end

  let(:bronze_plan) do
    {
      "id" => "bronze_id",
      "name" => "Bronze Plan",
      "free" => false,
      "code" => "bronze",
      "price_per_year" => 48.0
    }
  end

  let(:raw_plan_data) do
    [free_plan, bronze_plan]
  end

  before do
    stub_feature_flags(hide_deprecated_billing_plans: false)
    allow(helper).to receive(:params).and_return(plan_id: 'bronze_id', namespace_id: nil)
    allow_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService) do |instance|
      allow(instance).to receive(:execute).and_return(raw_plan_data)
    end
  end

  describe '#subscription_data' do
    let_it_be(:user) { create(:user, setup_for_company: nil, name: 'First Last') }
    let_it_be(:user2) { create(:user) }
    let_it_be(:group) { create(:group, name: 'My Namespace') }

    before do
      allow(helper).to receive(:params).and_return(plan_id: 'bronze_id', namespace_id: group.id.to_s, source: 'some_source')
      allow(helper).to receive(:current_user).and_return(user)
      group.add_owner(user)
      group.add_guest(user2)
    end

    subject { helper.subscription_data([group]) }

    it { is_expected.to include(setup_for_company: '') }
    it { is_expected.to include(full_name: 'First Last') }
    it { is_expected.to include(available_plans: '[{"id":"bronze_id","code":"bronze","price_per_year":48.0,"name":"Bronze Plan"}]') }
    it { is_expected.to include(plan_id: 'bronze_id') }
    it { is_expected.to include(namespace_id: group.id.to_s) }
    it { is_expected.to include(source: 'some_source') }
    it { is_expected.to include(group_data: %Q{[{"id":#{group.id},"account_id":null,"name":"My Namespace","full_path":"my_namespace"}]}) }
    it { is_expected.to include(trial: 'false') }
    it { is_expected.to include(new_trial_registration_path: '/-/trial_registrations/new') }

    context 'when user is on trial' do
      before do
        user.namespace.build_gitlab_subscription(trial: true)
      end

      it { is_expected.to include(trial: 'true') }
    end

    describe 'new_user' do
      where(:referer, :expected_result) do
        'http://example.com/users/sign_up/welcome?foo=bar'             | 'true'
        'http://example.com'                                           | 'false'
        nil                                                            | 'false'
      end

      with_them do
        before do
          allow(helper).to receive(:request).and_return(double(referer: referer))
        end

        it { is_expected.to include(new_user: expected_result) }
      end
    end

    context 'when bronze_plan is deprecated' do
      let(:bronze_plan) do
        {
          "id" => "bronze_id",
          "name" => "Bronze Plan",
          "deprecated" => true,
          "free" => false,
          "code" => "bronze",
          "price_per_year" => 48.0
        }
      end

      it { is_expected.to include(available_plans: '[{"id":"bronze_id","code":"bronze","price_per_year":48.0,"deprecated":true,"name":"Bronze Plan"}]') }
    end

    context 'when a plan is eligible to use a promo code' do
      let(:bronze_plan) do
        {
          "id" => "bronze_id",
          "name" => "Bronze Plan",
          "deprecated" => true,
          "free" => false,
          "code" => "bronze",
          "price_per_year" => 48.0,
          "eligible_to_use_promo_code": true
        }
      end

      it { is_expected.to include(available_plans: '[{"id":"bronze_id","code":"bronze","price_per_year":48.0,"eligible_to_use_promo_code":true,"deprecated":true,"name":"Bronze Plan"}]') }
    end

    context 'when bronze_plan has hide_card attribute set to true' do
      let(:bronze_plan) do
        {
          "id" => "bronze_id",
          "name" => "Bronze Plan",
          "deprecated" => false,
          "hide_card" => true,
          "free" => false,
          "code" => "bronze",
          "price_per_year" => 48.0
        }
      end

      context 'and is set to hide_deprecated_billing_plans true' do
        before do
          stub_feature_flags(hide_deprecated_billing_plans: true)
        end

        it { is_expected.not_to include(available_plans: "[{\"id\":\"bronze_id\",\"code\":\"bronze\",\"price_per_year\":48.0,\"deprecated\":false,\"name\":\"Bronze Plan\",\"hide_card\":true}]") }
      end

      context 'and is set to false' do
        it { is_expected.to include(available_plans: "[{\"id\":\"bronze_id\",\"code\":\"bronze\",\"price_per_year\":48.0,\"deprecated\":false,\"name\":\"Bronze Plan\",\"hide_card\":true}]") }
      end
    end
  end

  describe '#plan_title' do
    subject { helper.plan_title }

    it { is_expected.to eq('Bronze') }

    context 'no plan_id URL parameter present' do
      before do
        allow(helper).to receive(:params).and_return({})
      end

      it { is_expected.to eq(nil) }
    end

    context 'a non-existing plan_id URL parameter present' do
      before do
        allow(helper).to receive(:params).and_return(plan_id: 'xxx')
      end

      it { is_expected.to eq(nil) }
    end
  end

  describe '#buy_addon_data' do
    subject(:buy_addon_data) { helper.buy_addon_data(group, account_id, active_subscription, anchor, purchased_product) }

    let_it_be(:group) { create(:group, name: 'My Namespace') }
    let_it_be(:user) { create(:user, name: 'First Last') }
    let_it_be(:account_id) { '111111111111' }
    let_it_be(:active_subscription) { { name: 'S-000000000' } }

    let(:anchor) { 'pipelines-quota-tab' }
    let(:purchased_product) { 'CI Minutes' }

    before do
      allow(helper).to receive(:current_user).and_return(user)
      allow(helper).to receive(:params).and_return({ selected_group: group.id.to_s, source: 'some_source' })
      group.add_owner(user)
    end

    it { is_expected.to include(namespace_id: group.id.to_s) }
    it { is_expected.to include(active_subscription: active_subscription) }
    it { is_expected.to include(source: 'some_source') }
    it { is_expected.to include(group_data: %Q{[{"id":#{group.id},"account_id":"#{account_id}","name":"My Namespace","full_path":"my_namespace"}]}) }
    it { is_expected.to include(redirect_after_success: group_usage_quotas_path(group, anchor: anchor, purchased_product: purchased_product)) }
  end
end
