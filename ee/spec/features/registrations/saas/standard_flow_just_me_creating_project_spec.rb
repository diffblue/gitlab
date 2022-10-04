# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Standard flow for user picking just me and creating a project', :js, :saas, :saas_registration do
  it 'registers the user and creates a group and project reaching onboarding', :sidekiq_inline do
    user_signs_up

    expect_to_see_welcome_form

    fills_in_welcome_form
    click_on 'Continue'

    expect_to_see_group_and_project_creation_form

    fills_in_group_and_project_creation_form
    click_on 'Create project'

    expect_to_be_in_continuous_onboarding

    click_on 'Ok, let\'s go'

    expect_to_be_in_learn_gitlab
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

    page.within('[data-testid="welcome-form"]') do
      expect(page).to have_content('Role')
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

  def user_email
    'onboardinguser@example.com'
  end

  def user
    User.find_by(email: user_email)
  end

  def fills_in_group_and_project_creation_form
    # The groups_and_projects_controller (on `click_on 'Create project'`) is over
    # the query limit threshold, so we have to adjust it.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/338737
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(137)

    fill_in 'group_name', with: 'Test Group'
    fill_in 'blank_project_name', with: 'Test Project'
  end

  def expect_to_be_in_continuous_onboarding
    expect(page).to have_content 'Get started with GitLab'
  end

  def expect_to_be_in_learn_gitlab
    expect(page).to have_content('Learn GitLab')
    expect(page).to have_content('GitLab is better with colleagues!')
  end
end
