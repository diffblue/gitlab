# frozen_string_literal: true

RSpec.shared_examples_for 'subscription form data' do |js_selector|
  before do
    allow(view).to receive(:subscription_data).and_return(
      setup_for_company: 'true',
      full_name: 'First Last',
      plan_data: '[{"id":"bronze_id","code":"bronze","price_per_year":48.0}]',
      plan_id: 'bronze_id',
      source: 'some_source'
    )
  end

  subject { render }

  it { is_expected.to have_selector("#{js_selector}[data-setup-for-company='true']") }
  it { is_expected.to have_selector("#{js_selector}[data-full-name='First Last']") }
  it { is_expected.to have_selector("#{js_selector}[data-plan-data='[{\"id\":\"bronze_id\",\"code\":\"bronze\",\"price_per_year\":48.0}]']") }
  it { is_expected.to have_selector("#{js_selector}[data-plan-id='bronze_id']") }
  it { is_expected.to have_selector("#{js_selector}[data-source='some_source']") }
end

RSpec.shared_examples_for 'buy minutes addon form data' do |js_selector|
  let_it_be(:group) { create(:group) }
  let_it_be(:account_id) { '111111111111' }
  let_it_be(:active_subscription) { { name: 'S-000000000' } }

  before do
    allow(view).to receive(:buy_addon_data).with(@group, @account_id, @active_subscription, 'pipelines-quota-tab', s_('Checkout|CI minutes')).and_return(
      active_subscription: active_subscription,
      group_data: '[{"id":"ci_minutes_plan_id","code":"ci_minutes","price_per_year":10.0}]',
      namespace_id: '1',
      plan_id: 'ci_minutes_plan_id',
      source: 'some_source',
      redirect_after_success: '/groups/my-ci-minutes-group/-/usage_quotas#pipelines-quota-tab'
    )
  end

  subject { render }

  it { is_expected.to have_selector("#{js_selector}[data-active-subscription-name='S-000000000']") }
  it { is_expected.to have_selector("#{js_selector}[data-group-data='[{\"id\":\"ci_minutes_plan_id\",\"code\":\"ci_minutes\",\"price_per_year\":10.0}]']") }
  it { is_expected.to have_selector("#{js_selector}[data-plan-id='ci_minutes_plan_id']") }
  it { is_expected.to have_selector("#{js_selector}[data-namespace-id='1']") }
  it { is_expected.to have_selector("#{js_selector}[data-source='some_source']") }
  it { is_expected.to have_selector("#{js_selector}[data-redirect-after-success='/groups/my-ci-minutes-group/-/usage_quotas#pipelines-quota-tab']") }
end

RSpec.shared_examples_for 'buy storage addon form data' do |js_selector|
  let_it_be(:group) { create(:group) }
  let_it_be(:account_id) { '111111111111' }
  let_it_be(:active_subscription) { { name: 'S-000000000' } }

  before do
    allow(view).to receive(:buy_addon_data).with(@group, @account_id, @active_subscription, 'storage-quota-tab', s_('Checkout|a storage subscription')).and_return(
      active_subscription: active_subscription,
      group_data: '[{"id":"storage_plan_id","code":"storage","price_per_year":10.0}]',
      namespace_id: '2',
      plan_id: 'storage_plan_id',
      source: 'some_source',
      redirect_after_success: '/groups/my-group/-/usage_quotas#storage-quota-tab'
    )
  end

  subject { render }

  it { is_expected.to have_selector("#{js_selector}[data-active-subscription-name='S-000000000']") }
  it { is_expected.to have_selector("#{js_selector}[data-group-data='[{\"id\":\"storage_plan_id\",\"code\":\"storage\",\"price_per_year\":10.0}]']") }
  it { is_expected.to have_selector("#{js_selector}[data-plan-id='storage_plan_id']") }
  it { is_expected.to have_selector("#{js_selector}[data-namespace-id='2']") }
  it { is_expected.to have_selector("#{js_selector}[data-source='some_source']") }
  it { is_expected.to have_selector("#{js_selector}[data-redirect-after-success='/groups/my-group/-/usage_quotas#storage-quota-tab']") }
end
