# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial flow for user picking just me and creating a project', :js, :saas, :saas_registration,
feature_category: :onboarding do
  it 'registers the user and creates a group and project reaching onboarding', :sidekiq_inline do
    visit new_trial_registration_path(glm_params)

    expect_to_be_on_trial_user_registration

    user_signs_up_through_trial_registration

    expect_to_see_account_confirmation_page

    confirm_account

    user_signs_in

    expect_to_see_welcome_form

    fills_in_welcome_form
    click_on 'Continue'

    expect_to_see_company_form

    fill_in_company_form
    click_on 'Continue'

    expect_to_see_group_and_project_creation_form

    fills_in_group_and_project_creation_form
    click_on 'Create project'

    expect_to_be_in_continuous_onboarding

    click_on 'Ok, let\'s go'

    expect_to_be_in_learn_gitlab
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

  def fills_in_welcome_form
    select 'Software Developer', from: 'user_role'
    select 'A different reason', from: 'user_registration_objective'
    fill_in 'Why are you signing up? (optional)', with: 'My reason'

    choose 'Just me'
    check 'I\'d like to receive updates about GitLab via email'
  end

  def expect_to_be_on_trial_user_registration
    expect(page).to have_content('Free 30-day trial')
  end

  def expect_to_see_welcome_form
    expect(page).to have_content('Welcome to GitLab, Registering!')

    page.within(welcome_form_selector) do
      expect(page).to have_content('Role')
      expect(page).to have_field('user_role', valid: false)
      expect(page).to have_field('user_setup_for_company_true', valid: false)
      expect(page).to have_content('I\'m signing up for GitLab because:')
      expect(page).to have_content('Who will be using this GitLab trial?')
      expect(page).not_to have_content('What would you like to do?')
    end
  end

  def fill_in_company_form
    expect(GitlabSubscriptions::CreateTrialOrLeadService).to receive(:new).with(
      user: user,
      params: company_params_trial_true
    ).and_return(instance_double(GitlabSubscriptions::CreateTrialOrLeadService, execute: ServiceResponse.success))

    fill_in 'company_name', with: 'Test Company'
    select '1 - 99', from: 'company_size'
    select 'United States of America', from: 'country'
    select 'Florida', from: 'state'
    fill_in 'phone_number', with: '+1234567890'
    fill_in 'website_url', with: 'https://gitlab.com'
  end

  def fills_in_group_and_project_creation_form
    # The groups_and_projects_controller (on `click_on 'Create project'`) is over
    # the query limit threshold, so we have to adjust it.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/338737
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(143)

    service_instance = instance_double(GitlabSubscriptions::Trials::ApplyTrialService)
    allow(GitlabSubscriptions::Trials::ApplyTrialService).to receive(:new).and_return(service_instance)

    expect(service_instance).to receive(:execute).and_return(ServiceResponse.success)

    trial_user_information = {
      namespace_id: anything,
      gitlab_com_trial: true,
      sync_to_gl: true
    }.merge(glm_params)

    expect(GitlabSubscriptions::Trials::ApplyTrialWorker)
      .to receive(:perform_async).with(
        user.id,
        trial_user_information
      ).and_call_original

    fill_in 'group_name', with: 'Test Group'
    fill_in 'blank_project_name', with: 'Test Project'
  end

  def company_params_trial_true
    ActionController::Parameters.new(
      {
        company_name: 'Test Company',
        company_size: '1-99',
        phone_number: '+1234567890',
        country: 'US',
        state: 'FL',
        website_url: 'https://gitlab.com',
        trial_onboarding_flow: 'true',
        # these are the passed through params
        role: 'software_developer',
        registration_objective: 'other',
        jobs_to_be_done_other: 'My reason'
      }.merge(glm_params)
    ).permit!
  end
end
