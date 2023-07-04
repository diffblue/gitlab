# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Subscription flow for existing user with eligible group', :js, feature_category: :subscription_management do
  include SaasRegistrationHelpers
  include SubscriptionPortalHelpers

  let_it_be(:user) { create(:user) }.freeze
  let_it_be(:group) { create(:group, name: 'Existing Group').tap { |g| g.add_owner(user) } }.freeze
  let_it_be(:plans_data) { billing_plans_data }.freeze
  let_it_be(:premium_plan) { plans_data.find { |plan_data| plan_data[:id] == 'premium-external-id' } }.freeze

  before do
    stub_signing_key
    stub_eligible_namespaces
    stub_billing_plans(nil)
    stub_invoice_preview('null', premium_plan[:id])

    sign_in(user)
  end

  it 'purchases subscription by selecting existing group' do
    visit new_subscriptions_path(plan_id: premium_plan[:id])

    expect_to_see_checkout_form

    stub_invoice_preview(group.id, premium_plan[:id])

    select_gitlab_group('Existing Group')

    fill_in_checkout_form

    expect(page).to have_current_path(group_billings_path(group, plan_id: premium_plan[:id], purchased_quantity: 1))
  end

  it 'purchases subscription by selecting create a new group' do
    visit new_subscriptions_path(plan_id: premium_plan[:id])

    expect_to_see_checkout_form

    stub_new_group_invoice

    select_gitlab_group('Create a new group')

    within_fieldset('Name of company or organization using GitLab') do
      fill_in with: 'Test company'
    end

    fill_in_checkout_form

    fill_in 'Group name (your organization)', with: '@invalid group name'

    click_on 'Get started'

    expect_to_see_group_validation_errors

    fill_in 'Group name (your organization)', with: 'Test Company'

    click_on 'Get started'

    expect_to_be_on_group_overview
  end

  def fill_in_checkout_form
    click_button 'Continue to billing'

    within_fieldset('Country') do
      select 'United States of America'
    end

    within_fieldset('Street address') do
      first("input[type='text']").fill_in with: '123 fake street'
    end

    within_fieldset('City') do
      fill_in with: 'Fake city'
    end

    within_fieldset('State') do
      select 'Florida'
    end

    within_fieldset('Zip code') do
      fill_in with: 'A1B 2C3'
    end

    click_button 'Continue to payment'

    stub_confirm_purchase
  end

  def stub_confirm_purchase
    allow_next_instance_of(GitlabSubscriptions::CreateService) do |instance|
      allow(instance).to receive(:execute).and_return({ success: true, data: 'foo' })
    end

    # this is an ad-hoc solution to skip the zuora step and allow 'confirm purchase' button to show up
    page.execute_script <<~JS
      document.querySelector('[data-testid="subscription_app"]').__vue__.$store.dispatch('fetchPaymentMethodDetailsSuccess')
    JS

    click_button 'Confirm purchase'
  end

  def select_gitlab_group(option)
    within_fieldset('GitLab group') do
      select option
    end
  end

  def stub_eligible_namespaces
    allow(Gitlab::SubscriptionPortal::Client)
      .to receive(:filter_purchase_eligible_namespaces)
            .and_return(
              success: true,
              data: [
                { 'id' => group.id, 'accountId' => nil, 'subscription' => nil }
              ])
  end

  def stub_new_group_invoice
    stub_full_request(graphql_url, method: :post)
      .with(body: request_body_string)
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: stubbed_invoice_preview_response_body
      )
  end

  def request_body_string
    # rubocop:disable Layout/LineLength
    "{\"operationName\":\"GetInvoicePreview\",\"variables\":{\"planId\":\"premium-external-id\",\"quantity\":1,\"namespaceId\":\"new_group\"},\"query\":\"query GetInvoicePreview($planId: ID!, $quantity: Int!, $promoCode: String, $namespaceId: ID) {\\n  invoicePreview(\\n    planId: $planId\\n    quantity: $quantity\\n    promoCode: $promoCode\\n    namespaceId: $namespaceId\\n  ) {\\n    invoice {\\n      amountWithoutTax\\n      __typename\\n    }\\n    invoiceItem {\\n      chargeAmount\\n      processingType\\n      unitPrice\\n      __typename\\n    }\\n    metaData {\\n      showPromotionalOfferText\\n      __typename\\n    }\\n    __typename\\n  }\\n}\\n\"}"
    # rubocop:enable Layout/LineLength
  end

  def expect_to_be_on_group_overview
    expect(page).to have_content('Subscription successfully applied to "Test Company"')
    expect(page).to have_content('Group information')
    expect(page).to have_content('Subgroups and projects')
  end
end
