# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Subscription flow for paid plan', :js, :saas_registration,
feature_category: :onboarding do
  include SubscriptionPortalHelpers

  context 'when use_invoice_preview_api_in_saas_purchase feature flag is enabled' do
    it 'registers the user and sends them back to subscription checkout' do
      stub_feature_flags(use_invoice_preview_api_in_saas_purchase: true)

      stub_signing_key

      stub_invoice_preview

      registers_from_subscription

      expect_to_see_account_confirmation_page

      confirm_account

      user_signs_in

      expect_to_see_welcome_form

      fills_in_welcome_form
      click_on 'Continue'

      expect_to_see_checkout_form
    end
  end

  context 'when use_invoice_preview_api_in_saas_purchase feature flag is disabled' do
    it 'registers the user and sends them back to subscription checkout' do
      stub_feature_flags(use_invoice_preview_api_in_saas_purchase: false)

      registers_from_subscription

      expect_to_see_account_confirmation_page

      confirm_account

      user_signs_in

      expect_to_see_welcome_form

      fills_in_welcome_form
      click_on 'Continue'

      expect_to_see_checkout_form
    end
  end

  def registers_from_subscription
    new_user = build(:user, name: 'Registering User', email: user_email)

    visit new_subscriptions_path(plan_id: 'bronze_id')

    fill_in 'First name', with: new_user.first_name
    fill_in 'Last name', with: new_user.last_name
    fill_in 'Username', with: new_user.username
    fill_in 'Email', with: new_user.email
    fill_in 'Password', with: new_user.password

    wait_for_all_requests

    click_button 'Register'
  end

  def fills_in_welcome_form
    plan_data = [
      {
        "id" => "bronze_id",
        "name" => "Bronze Plan",
        "free" => false,
        "code" => "bronze",
        "price_per_year" => 48.0
      }
    ]
    allow_next_instance_of(GitlabSubscriptions::FetchSubscriptionPlansService) do |instance|
      allow(instance).to receive(:execute).and_return(plan_data)
    end

    subscription_portal_url = ::Gitlab::Routing.url_helpers.subscription_portal_url

    stub_request(:get, "#{subscription_portal_url}/payment_forms/paid_signup_flow")
      .with(
        headers: {
          'Accept' => 'application/json',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type' => 'application/json',
          'User-Agent' => 'Ruby',
          'X-Admin-Email' => 'gl_com_api@gitlab.com',
          'X-Admin-Token' => 'customer_admin_token'
        })
      .to_return(status: 200, body: "", headers: {})

    select 'Software Developer', from: 'user_role'
    select 'A different reason', from: 'user_registration_objective'
    fill_in 'Why are you signing up? (optional)', with: 'My reason'

    choose 'My company or team'
    choose 'Create a new project' # not sure why this matters on a paid plan
  end

  def expect_to_see_welcome_form
    expect(page).to have_content('Welcome to GitLab, Registering!')

    page.within(welcome_form_selector) do
      expect(page).to have_content('Role')
      expect(page).to have_field('user_role', valid: false)
      expect(page).to have_field('user_setup_for_company_true', valid: false)
      expect(page).to have_content('I\'m signing up for GitLab because:')
      expect(page).to have_content('Who will be using this GitLab subscription?')
      expect(page).to have_content('What would you like to do?')
      expect(page).not_to have_content('I\'d like to receive updates about GitLab via email')
    end
  end

  def expect_to_see_checkout_form
    expect(page).to have_content('Checkout')
    expect(page).to have_content('Subscription details')
  end
end
