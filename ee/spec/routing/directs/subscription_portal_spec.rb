# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Custom URLs', 'Subscription Portal', feature_category: :subscription_management do
  include SubscriptionPortalHelper

  let(:env_value) { nil }

  before do
    stub_env('CUSTOMER_PORTAL_URL', env_value)
  end

  describe 'subscription_portal_legacy_sign_in_url' do
    subject { subscription_portal_legacy_sign_in_url }

    it { is_expected.to eq("#{staging_customers_url}/customers/sign_in?legacy=true") }
  end

  describe 'subscription_portal_payment_form_url' do
    subject { subscription_portal_payment_form_url }

    it { is_expected.to eq("#{staging_customers_url}/payment_forms/cc_validation") }
  end

  describe 'subscription_portal_registration_validation_form_url' do
    subject { subscription_portal_registration_validation_form_url }

    it { is_expected.to eq("#{staging_customers_url}/payment_forms/cc_registration_validation") }
  end

  describe 'subscription_portal_manage_url' do
    subject { subscription_portal_manage_url }

    it { is_expected.to eq("#{staging_customers_url}/subscriptions") }
  end

  describe 'subscription_portal_graphql_url' do
    subject { subscription_portal_graphql_url }

    it { is_expected.to eq("#{staging_customers_url}/graphql") }
  end

  describe 'subscriptions_comparison_url' do
    subject { subscriptions_comparison_url }

    link_match = %r{\Ahttps://about\.gitlab\.((cn/pricing/saas)|(com/pricing/gitlab-com))/feature-comparison\z}

    it { is_expected.to match(link_match) }
  end

  describe 'subscription_portal_more_minutes_url' do
    subject { subscription_portal_more_minutes_url }

    it { is_expected.to eq("#{staging_customers_url}/buy_pipeline_minutes") }
  end

  describe 'subscription_portal_more_storage_url' do
    subject { subscription_portal_more_storage_url }

    it { is_expected.to eq("#{staging_customers_url}/buy_storage") }
  end

  describe 'subscription_portal_gitlab_plans_url' do
    subject { subscription_portal_gitlab_plans_url }

    it { is_expected.to eq("#{staging_customers_url}/gitlab_plans") }
  end

  describe 'subscription_portal_edit_account_url' do
    subject { subscription_portal_edit_account_url }

    it { is_expected.to eq("#{staging_customers_url}/customers/edit") }
  end

  describe 'subscription_portal_add_extra_seats_url' do
    let(:group_id) { 153 }

    subject { subscription_portal_add_extra_seats_url(group_id) }

    it { is_expected.to eq("#{staging_customers_url}/gitlab/namespaces/#{group_id}/extra_seats") }
  end

  describe 'subscription_portal_upgrade_subscription_url' do
    let(:group_id) { 153 }
    let(:plan_id) { 5 }

    subject { subscription_portal_upgrade_subscription_url(group_id, plan_id) }

    it { is_expected.to eq("#{staging_customers_url}/gitlab/namespaces/#{group_id}/upgrade/#{plan_id}") }
  end

  describe 'subscription_portal_renew_subscription_url' do
    let(:group_id) { 153 }

    subject { subscription_portal_renew_subscription_url(group_id) }

    it { is_expected.to eq("#{staging_customers_url}/gitlab/namespaces/#{group_id}/renew") }
  end
end
