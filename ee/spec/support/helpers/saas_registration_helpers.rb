# frozen_string_literal: true

require_relative 'subscription_portal_helpers'

module SaasRegistrationHelpers
  include IdentityVerificationHelpers
  include SubscriptionPortalHelpers

  def user
    User.find_by(email: user_email)
  end

  def user_email
    'onboardinguser@example.com'
  end

  def user_signs_in
    new_password = User.random_password
    user.update!(password: new_password)

    fill_in 'Password', with: new_password

    wait_for_all_requests

    click_button 'Sign in'
  end

  def expect_to_see_account_confirmation_page
    expect(page).to have_content('Almost there')
    expect(page).to have_content('Please check your email')
  end

  def confirm_account
    token = user.confirmation_token
    visit user_confirmation_path(confirmation_token: token)
  end

  def regular_sign_up(params = {})
    user_signs_up(params)

    expect_to_see_account_confirmation_page

    confirm_account

    user_signs_in
  end

  def subscription_regular_sign_up
    stub_signing_key

    user_registers_from_subscription

    expect_to_see_account_confirmation_page

    confirm_account

    user_signs_in
  end

  def sso_sign_up(params = {}, name: 'Registering User')
    stub_feature_flags(
      arkose_labs_oauth_signup_challenge: true,
      identity_verification: true
    )

    with_omniauth_full_host do
      user_signs_up_with_sso(params, name: name)

      expect_to_see_identity_verification_page

      verify_email
    end

    expect_to_see_verification_successful_page
  end

  def user_signs_up(params = {})
    new_user = build(:user, name: 'Registering User', email: user_email)

    visit new_user_registration_path(params)

    fill_in 'First name', with: new_user.first_name
    fill_in 'Last name', with: new_user.last_name
    fill_in 'Username', with: new_user.username
    fill_in 'Email', with: new_user.email
    fill_in 'Password', with: new_user.password

    wait_for_all_requests

    click_button 'Register'
  end

  def user_signs_up_with_sso(params = {}, provider: 'google_oauth2', name: 'Registering User')
    mock_auth_hash(provider, 'external_uid', user_email, name: name)
    stub_omniauth_setting(block_auto_created_users: false)
    allow(::Arkose::Settings).to receive(:enabled?).and_return(true)

    if block_given?
      yield
    else
      visit new_user_registration_path(params)
    end

    wait_for_all_requests

    click_link_or_button "oauth-login-#{provider}"
    solve_arkose_verify_challenge(saml: true)
  end

  def user_signs_up_through_subscription_with_sso(provider: 'google_oauth2')
    user_signs_up_with_sso({}, provider: provider) do
      stub_invoice_preview

      visit new_subscriptions_path(plan_id: 'bronze_id')
      # expect sign in here
    end
  end

  def user_signs_up_through_trial_with_sso(params = {}, provider: 'google_oauth2', name: 'Registering User')
    user_signs_up_with_sso({}, provider: provider, name: name) do
      visit new_trial_registration_path(params)

      expect_to_be_on_trial_user_registration
    end
  end

  def user_signs_up_through_signin_with_sso(params = {})
    user_signs_up_with_sso({}, provider: 'google_oauth2') do
      visit new_user_session_path(params)

      expect_to_be_on_user_sign_in
    end
  end

  def trial_registration_sign_up(params = {})
    visit new_trial_registration_path(params)

    expect_to_be_on_trial_user_registration

    user_signs_up_through_trial_registration

    expect_to_see_account_confirmation_page

    confirm_account

    user_signs_in
  end

  def sso_trial_registration_sign_up(params = {}, name: 'Registering User')
    stub_feature_flags(
      arkose_labs_oauth_signup_challenge: true,
      identity_verification: true
    )

    with_omniauth_full_host do
      user_signs_up_through_trial_with_sso(params, name: name)

      expect_to_see_identity_verification_page

      verify_email
    end

    expect_to_see_verification_successful_page
  end

  def sso_subscription_sign_up
    stub_signing_key
    stub_feature_flags(
      arkose_labs_oauth_signup_challenge: true,
      identity_verification: true
    )

    with_omniauth_full_host do
      user_signs_up_through_subscription_with_sso

      expect_to_see_identity_verification_page

      verify_email
    end

    expect_to_see_verification_successful_page
  end

  def sso_signup_through_signin
    stub_feature_flags(
      arkose_labs_oauth_signup_challenge: true,
      identity_verification: true
    )

    with_omniauth_full_host do
      user_signs_up_through_signin_with_sso

      expect_to_see_identity_verification_page

      verify_email
    end

    expect_to_see_verification_successful_page
  end

  def user_signs_up_through_trial_registration
    new_user = build(:user, name: 'Registering User', email: user_email)

    fill_in 'new_user_first_name', with: new_user.first_name
    fill_in 'new_user_last_name', with: new_user.last_name
    fill_in 'new_user_username', with: new_user.username
    fill_in 'new_user_email', with: new_user.email
    fill_in 'new_user_password', with: new_user.password

    wait_for_all_requests

    click_button 'Continue'
  end

  def ensure_onboarding
    yield

    visit root_path

    yield
  end

  def ensure_onboarding_is_finished
    visit root_path
    expect(page).to have_current_path(root_path)
  end

  def user_registers_from_subscription
    new_user = build(:user, name: 'Registering User', email: user_email)

    stub_invoice_preview

    visit new_subscriptions_path(plan_id: 'bronze_id')

    fill_in 'First name', with: new_user.first_name
    fill_in 'Last name', with: new_user.last_name
    fill_in 'Username', with: new_user.username
    fill_in 'Email', with: new_user.email
    fill_in 'Password', with: new_user.password

    wait_for_all_requests

    click_button 'Register'
  end

  def glm_params
    {
      glm_source: 'some_source',
      glm_content: 'some_content'
    }
  end

  def expect_to_be_in_import_process
    expect(page).to have_content <<~MESSAGE.tr("\n", ' ')
      To connect GitHub repositories, you first need to authorize
      GitLab to access the list of your GitHub repositories.
    MESSAGE
  end

  def expect_to_see_import_form
    expect_to_see_group_and_project_creation_form
    expect(page).to have_content('GitLab export')
  end

  def expect_to_be_on_trial_user_registration
    expect(page).to have_content('Free 30-day trial')
  end

  def expect_to_be_on_user_sign_in
    expect(page).to have_content('By signing in you accept')
  end

  def expect_to_be_in_learn_gitlab
    expect(page).to have_content('Learn GitLab')

    page.within('[data-testid="invite-modal"]') do
      expect(page).to have_content('GitLab is better with colleagues!')
      expect(page).to have_content('Congratulations on creating your project')
    end
  end

  def expect_to_be_in_continuous_onboarding
    expect(page).to have_content 'Get started with GitLab'
  end

  def expect_to_see_group_and_project_creation_form
    expect(user).to be_email_opted_in # minor item that isn't important to see in the example itself

    expect(page).to have_content('Create or import your first project')
    expect(page).to have_content('Projects help you organize your work')
    expect(page).to have_content('Your project will be created at:')
  end

  def expect_to_see_company_form
    expect(page).to have_content 'About your company'
  end

  def expect_to_apply_trial(glm: true)
    service_instance = instance_double(GitlabSubscriptions::Trials::ApplyTrialService)
    allow(GitlabSubscriptions::Trials::ApplyTrialService).to receive(:new).and_return(service_instance)

    expect(service_instance).to receive(:execute).and_return(ServiceResponse.success)

    trial_user_information = {
      namespace_id: anything,
      gitlab_com_trial: true,
      sync_to_gl: true,
      namespace: {
        id: anything,
        name: 'Test Group',
        path: 'test-group',
        kind: 'group',
        trial_ends_on: nil
      }
    }

    trial_user_information.merge!(glm_params) if glm

    expect(GitlabSubscriptions::Trials::ApplyTrialWorker)
      .to receive(:perform_async).with(
        user.id,
        trial_user_information
      ).and_call_original
  end

  def toggle_trial
    find('[data-testid="trial_onboarding_flow"] button').click
  end

  def expect_to_be_on_projects_dashboard
    # we set email opted in at the controller layer if setup for company is true
    expect(user).to be_email_opted_in # minor item that isn't important to see in the example itself

    expect(page).to have_content 'There are no projects available to be displayed here.'
  end

  def expect_to_be_on_projects_dashboard_with_zero_authorized_projects
    expect(user).to be_email_opted_in # minor item that isn't important to see in the example itself

    expect(page).to have_content 'Welcome to GitLab'
    expect(page).to have_content 'Faster releases. Better code. Less pain.'
  end

  def expect_to_see_group_overview_page
    expect(page).to have_content('Welcome to GitLab, Registering!')
    expect(page).to have_content('Group information')
    expect(page).to have_content('Subgroups and projects')
  end

  def welcome_form_selector
    '[data-testid="welcome-form"]'
  end

  def expect_to_see_subscription_welcome_form
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

  def fills_in_group_and_project_creation_form
    # The groups_and_projects_controller (on `click_on 'Create project'`) is over
    # the query limit threshold, so we have to adjust it.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/404805
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(160)

    fill_in 'group_name', with: 'Test Group'
    fill_in 'blank_project_name', with: 'Test Project'
  end

  def fills_in_group_and_project_creation_form_with_trial(glm: true)
    fills_in_group_and_project_creation_form

    service_instance = instance_double(GitlabSubscriptions::Trials::ApplyTrialService)
    allow(GitlabSubscriptions::Trials::ApplyTrialService).to receive(:new).and_return(service_instance)

    expect(service_instance).to receive(:execute).and_return(ServiceResponse.success)

    trial_user_information = {
      namespace_id: anything,
      gitlab_com_trial: true,
      sync_to_gl: true,
      namespace: {
        id: anything,
        name: 'Test Group',
        path: 'test-group',
        kind: 'group',
        trial_ends_on: nil
      }
    }

    trial_user_information.merge!(glm_params) if glm

    expect(GitlabSubscriptions::Trials::ApplyTrialWorker)
      .to receive(:perform_async).with(
        user.id,
        trial_user_information
      ).and_call_original
  end

  def fill_in_company_form(with_last_name: false, trial: true, glm: true, success: true)
    result = if success
               ServiceResponse.success
             else
               ServiceResponse.error(message: '_company_lead_fail_')
             end

    expect(GitlabSubscriptions::CreateTrialOrLeadService).to receive(:new).with(
      user: user,
      params: company_params(user, trial: trial, glm: glm)
    ).and_return(instance_double(GitlabSubscriptions::CreateTrialOrLeadService, execute: result))

    fill_in_company_user_last_name if with_last_name
    fill_company_form_fields
  end

  def fill_in_company_user_last_name
    fill_in 'last_name', with: 'User'
  end

  def fill_company_form_fields
    fill_in 'company_name', with: 'Test Company'
    select '1 - 99', from: 'company_size'
    select 'United States of America', from: 'country'
    select 'Florida', from: 'state'
    fill_in 'phone_number', with: '+1234567890'
    fill_in 'website_url', with: 'https://gitlab.com'
  end

  def company_params(user, trial: true, glm: true)
    base_params = ActionController::Parameters.new(
      company_name: 'Test Company',
      company_size: '1-99',
      first_name: user.first_name,
      last_name: 'User',
      phone_number: '+1234567890',
      country: 'US',
      state: 'FL',
      website_url: 'https://gitlab.com',
      trial_onboarding_flow: trial.to_s,
      # these are the passed through params
      role: 'software_developer',
      registration_objective: 'other',
      jobs_to_be_done_other: 'My reason'
    ).permit!

    return base_params unless glm

    base_params.merge(glm_params)
  end

  def stub_subscription_customers_dot_requests
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
  end

  def expect_to_see_checkout_form
    expect(page).to have_content('Checkout')
    expect(page).to have_content('Subscription details')
  end

  def fill_in_checkout_form
    if user.setup_for_company
      within_fieldset('Name of company or organization using GitLab') do
        fill_in with: 'Test company'
      end
    end

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

    expect(GitlabSubscriptions::CreateService).to receive(:new).with(
      user,
      group: an_instance_of(Group),
      customer_params: customer_params,
      subscription_params: subscription_params
    )

    # this is an ad-hoc solution to skip the zuora step and allow 'confirm purchase' button to show up
    page.execute_script <<~JS
      document.querySelector('[data-testid="subscription_app"]').__vue__.$store.dispatch('fetchPaymentMethodDetailsSuccess')
    JS

    click_button 'Confirm purchase'
  end

  def expect_to_see_subscriptions_group_edit_page
    prefilled_group_name = user.setup_for_company ? 'Test company' : 'Registering User'

    expect(page).to have_content('Thanks for your purchase')
    expect(page).to have_content('Create your group')
    expect(page).to have_field('Group name (your organization)', with: prefilled_group_name)
  end

  def customer_params
    company = user.setup_for_company ? 'Test company' : nil

    ActionController::Parameters.new(
      country: 'US',
      address_1: '123 fake street',
      address_2: nil,
      city: 'Fake city',
      state: 'FL',
      zip_code: 'A1B 2C3',
      company: company
    ).permit!
  end

  def subscription_params(plan_id: 'bronze_id', quantity: 1)
    ActionController::Parameters.new(
      plan_id: plan_id,
      payment_method_id: nil,
      quantity: quantity
    ).permit!
  end

  def expect_to_see_group_validation_errors
    page.within('[data-testid="subscription-group-edit-form"]') do
      expect(page).to have_content("Name can contain only")
      expect(page).to have_content("It must start with")
    end
  end

  def expect_to_see_company_form_failure
    page.within('[data-testid="alert-danger"]') do
      expect(page).to have_content('_company_lead_fail_')
    end
  end

  def expect_to_send_iterable_request(invite: false)
    allow_next_instance_of(::Onboarding::CreateIterableTriggerService) do |instance|
      allow(instance).to receive(:execute).and_return(ServiceResponse.success)
    end

    product_interaction = if invite
                            'Invited User'
                          else
                            'Personal SaaS Registration'
                          end

    expect(::Onboarding::CreateIterableTriggerWorker).to receive(:perform_async).with(
      hash_including(
        provider: 'gitlab',
        work_email: user.email,
        uid: user.id,
        comment: 'My reason',
        role: 'software_developer',
        jtbd: 'other',
        product_interaction: product_interaction
      )
    ).and_call_original
  end

  def expect_not_to_send_iterable_request
    expect(::Onboarding::CreateIterableTriggerWorker).not_to receive(:perform_async)
  end
end

SaasRegistrationHelpers.prepend_mod
