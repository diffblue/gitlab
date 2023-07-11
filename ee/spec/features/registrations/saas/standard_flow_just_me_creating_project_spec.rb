# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Standard flow for user picking just me and creating a project', :js, :saas_registration, feature_category: :onboarding do
  where(:case_name, :sign_up_method) do
    [
      ['with regular sign up', -> { regular_sign_up }],
      ['with sso sign up', -> { sso_sign_up }]
    ]
  end

  with_them do
    it 'registers the user and creates a group and project reaching onboarding', :sidekiq_inline do
      sign_up_method.call

      expect_to_see_welcome_form
      expect_to_send_iterable_request

      fills_in_welcome_form
      click_on 'Continue'

      expect_to_see_group_and_project_creation_form

      fills_in_group_and_project_creation_form
      click_on 'Create project'

      expect_to_be_in_continuous_onboarding

      click_on 'Ok, let\'s go'

      expect_to_be_in_learn_gitlab
    end
  end

  it 'honors include readme checkbox' do
    regular_sign_up

    expect_to_see_welcome_form

    fills_in_welcome_form
    click_on 'Continue'

    expect_to_see_group_and_project_creation_form

    fill_in 'group_name', with: '@@@'
    fill_in 'blank_project_name', with: 'Test Project'
    uncheck 'Include a Getting Started README'
    click_on 'Create project'

    expect(find_field('Include a Getting Started README')).not_to be_checked
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
end
