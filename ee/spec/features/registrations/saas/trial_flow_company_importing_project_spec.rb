# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Trial flow for user picking company and importing a project', :js, :saas_registration,
feature_category: :onboarding do
  it 'registers the user and starts to import a project' do
    stub_application_setting(import_sources: %w[github gitlab_project])

    visit new_trial_registration_path

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

    click_on 'Import'

    expect_to_see_import_form

    fills_in_import_form
    click_on 'GitHub'

    expect_to_be_in_import_process
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

    choose 'My company or team'
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
      expect(page).not_to have_content('I\'d like to receive updates about GitLab via email')
    end
  end

  def fill_in_company_form
    expect(GitlabSubscriptions::CreateTrialOrLeadService).to receive(:new).with(
      user: user,
      params: company_params(glm: false)
    ).and_return(instance_double(GitlabSubscriptions::CreateTrialOrLeadService, execute: ServiceResponse.success))

    fill_in 'company_name', with: 'Test Company'
    select '1 - 99', from: 'company_size'
    select 'United States of America', from: 'country'
    select 'Florida', from: 'state'
    fill_in 'phone_number', with: '+1234567890'
    fill_in 'website_url', with: 'https://gitlab.com'
  end

  def user
    User.find_by(email: user_email)
  end

  def fills_in_import_form
    fill_in 'import_group_name', with: 'Test Group'
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
end
