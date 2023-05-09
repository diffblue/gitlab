# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Standard flow for user picking just me and importing a project', :js, :saas_registration,
feature_category: :onboarding do
  it 'registers the user and starts to import a project' do
    stub_application_setting(import_sources: %w[github gitlab_project])

    user_signs_up

    expect_to_see_account_confirmation_page

    confirm_account

    user_signs_in

    expect_to_see_welcome_form

    fills_in_welcome_form
    click_on 'Continue'

    expect_to_see_group_and_project_creation_form

    click_on 'Import'

    expect_to_see_import_form

    fills_in_import_form
    click_on 'GitHub'

    expect_to_be_in_import_process
  end

  def user_signs_up
    new_user = build(:user, name: 'Registering User', email: user_email)

    visit new_user_registration_path

    fill_in 'First name', with: new_user.first_name
    fill_in 'Last name', with: new_user.last_name
    fill_in 'Username', with: new_user.username
    fill_in 'Email', with: new_user.email
    fill_in 'Password', with: new_user.password

    wait_for_all_requests

    click_button 'Register'
  end

  def fills_in_welcome_form
    select 'Software Developer', from: 'user_role'
    select 'A different reason', from: 'user_registration_objective'
    fill_in 'Why are you signing up? (optional)', with: 'My reason'

    choose 'Just me'
    check 'I\'d like to receive updates about GitLab via email'
    choose 'Create a new project'
  end

  def expect_to_see_welcome_form
    expect(page).to have_content('Welcome to GitLab, Registering!')

    page.within(welcome_form_selector) do
      expect(page).to have_content('Role')
      expect(page).to have_field('user_role', valid: false)
      expect(page).to have_field('user_setup_for_company_true', valid: false)
      expect(page).to have_content('I\'m signing up for GitLab because:')
      expect(page).to have_content('Who will be using GitLab?')
      expect(page).to have_content('What would you like to do?')
    end
  end

  def expect_to_see_group_and_project_creation_form
    expect(user).to be_email_opted_in # minor item that isn't important to see in the example itself

    expect(page).to have_content('Create or import your first project')
    expect(page).to have_content('Projects help you organize your work')
    expect(page).to have_content('Your project will be created at:')
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
