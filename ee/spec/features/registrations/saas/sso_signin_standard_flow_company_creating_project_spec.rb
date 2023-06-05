# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Single sign on for signing up through sign in flow for user picking company and creating a project', :js, :saas_registration, feature_category: :onboarding do
  context 'when opting into a trial' do
    it 'registers the user and creates a group and project reaching onboarding', :sidekiq_inline do
      sso_signup_through_signin

      ensure_onboarding { expect_to_see_welcome_form }

      fills_in_welcome_form
      click_on 'Continue'

      ensure_onboarding { expect_to_see_company_form }

      fill_in_company_form(glm: false)
      toggle_trial
      click_on 'Continue'

      ensure_onboarding { expect_to_see_group_and_project_creation_form }

      fills_in_group_and_project_creation_form
      expect_to_apply_trial(glm: false)
      click_on 'Create project'

      expect_to_be_in_continuous_onboarding

      click_on 'Ok, let\'s go'

      expect_to_be_in_learn_gitlab
    end
  end

  context 'when not opting into a trial' do
    it 'registers the user and creates a group and project reaching onboarding' do
      sso_signup_through_signin

      expect_to_see_welcome_form

      fills_in_welcome_form
      click_on 'Continue'

      expect_to_see_company_form

      fill_in_company_form(trial: false, glm: false)
      click_on 'Continue'

      expect_to_see_group_and_project_creation_form

      fills_in_group_and_project_creation_form
      click_on 'Create project'

      expect_to_be_in_continuous_onboarding

      click_on 'Ok, let\'s go'

      expect_to_be_in_learn_gitlab
    end
  end

  def fills_in_welcome_form
    select 'Software Developer', from: 'user_role'
    select 'A different reason', from: 'user_registration_objective'
    fill_in 'Why are you signing up? (optional)', with: 'My reason'

    choose 'My company or team'
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
      expect(page).not_to have_content('I\'d like to receive updates about GitLab via email')
    end
  end
end
