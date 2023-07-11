# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Standard flow for user picking company and creating a project', :js, :saas_registration, feature_category: :onboarding do
  where(:case_name, :sign_up_method) do
    [
      ['with regular sign up', ->(params = {}) { regular_sign_up(params) }],
      ['with sso sign up', ->(params = {}) { sso_sign_up(params) }]
    ]
  end

  with_them do
    context 'when opting into a trial' do
      it 'registers the user and creates a group and project reaching onboarding', :sidekiq_inline do
        sign_up_method.call(glm_params)

        ensure_onboarding { expect_to_see_welcome_form }
        expect_not_to_send_iterable_request

        fills_in_welcome_form
        click_on 'Continue'

        ensure_onboarding { expect_to_see_company_form }

        fill_in_company_form
        toggle_trial
        click_on 'Continue'

        ensure_onboarding { expect_to_see_group_and_project_creation_form }

        fills_in_group_and_project_creation_form
        expect_to_apply_trial
        click_on 'Create project'

        expect_to_be_in_continuous_onboarding

        click_on 'Ok, let\'s go'

        expect_to_be_in_learn_gitlab
      end
    end

    context 'when user in automatic_trial_registration experiment' do
      it 'registers the user and creates a group and project reaching onboarding', :sidekiq_inline do
        stub_experiments(automatic_trial_registration: :candidate)

        sign_up_method.call(glm_params)

        expect_to_see_welcome_form

        fills_in_welcome_form
        click_on 'Continue'

        expect_to_see_company_form
        expect(page).to have_content 'Your GitLab Ultimate free trial lasts for 30 days.'
        expect(page).to have_content 'Free 30-day trial'
        expect(page).to have_content 'Invite unlimited colleagues'
        expect(page).to have_content 'Used by more than 100,000'

        fill_in_company_form
        click_on 'Start GitLab Ultimate free trial'

        expect_to_see_group_and_project_creation_form

        fills_in_group_and_project_creation_form
        expect_to_apply_trial
        click_on 'Create project'

        expect_to_be_in_continuous_onboarding

        click_on 'Ok, let\'s go'

        expect_to_be_in_learn_gitlab
      end
    end

    context 'when not opting into a trial' do
      it 'registers the user, has some lead submission failures and creates a group and project reaching onboarding' do
        sign_up_method.call

        ensure_onboarding { expect_to_see_welcome_form }

        fills_in_welcome_form
        click_on 'Continue'

        ensure_onboarding { expect_to_see_company_form }

        # failure
        fill_in_company_form(trial: false, glm: false, success: false)
        click_on 'Continue'

        expect_to_see_company_form_failure

        # success
        fill_in_company_form(trial: false, glm: false, success: true)
        click_on 'Continue'

        ensure_onboarding { expect_to_see_group_and_project_creation_form }

        fills_in_group_and_project_creation_form
        click_on 'Create project'

        expect_to_be_in_continuous_onboarding

        click_on 'Ok, let\'s go'

        expect_to_be_in_learn_gitlab
      end
    end
  end

  context 'when last name is missing for SSO and has to be filled in' do
    it 'registers the user, has some lead submission failures and creates a group and project reaching onboarding' do
      sso_sign_up(name: 'Registering')

      ensure_onboarding { expect_to_see_welcome_form }

      fills_in_welcome_form
      click_on 'Continue'

      ensure_onboarding { expect_to_see_company_form }

      # failure
      fill_company_form_fields
      click_on 'Continue'

      expect(page).to have_native_text_validation_message('last_name')

      # success
      fill_in_company_form(with_last_name: true, trial: false, glm: false)
      click_on 'Continue'

      ensure_onboarding { expect_to_see_group_and_project_creation_form }

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
