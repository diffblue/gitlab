# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Billings > Qrtly Reconciliation Alert', :js, :saas, feature_category: :billing_and_payments do
  include SubscriptionPortalHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:namespace) { create(:group) }
  let_it_be(:group_member) { create(:group_member, :owner, group: namespace, user: user) }
  let_it_be(:plan) { create(:premium_plan) }
  let_it_be(:plans_data) do
    Gitlab::Json.parse(File.read(Rails.root.join('ee/spec/fixtures/gitlab_com_plans.json'))).map do |data|
      data.deep_symbolize_keys
    end
  end

  let_it_be(:subscription) { create(:gitlab_subscription, namespace: namespace, hosted_plan: plan, seats: 15) }
  let_it_be(:page_path) { group_billings_path(namespace) }

  before do
    gitlab_plans_url = ::Gitlab::Routing.url_helpers.subscription_portal_gitlab_plans_url

    stub_signing_key
    stub_ee_application_setting(should_check_namespace_plan: true)
    stub_full_request("#{gitlab_plans_url}?plan=#{plan.name}&namespace_id=#{namespace.id}")
      .to_return(status: 200, body: plans_data.to_json)
    stub_subscription_management_data(namespace.id)
    sign_in(user)
  end

  context 'when qrtly reconciliation is available' do
    before do
      create(:upcoming_reconciliation, :saas, namespace: namespace)
      visit(page_path)
    end

    it_behaves_like 'a visible dismissible qrtly reconciliation alert'
  end

  context 'when qrtly reconciliation is not available' do
    before do
      visit(page_path)
    end

    it_behaves_like 'a hidden qrtly reconciliation alert'
  end
end
