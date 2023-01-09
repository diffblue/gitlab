# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Standard flow for user picking company and creating a project', :js, :saas, :saas_registration,
feature_category: :onboarding do
  context 'when opting into a trial' do
    it 'registers the user and creates a group and project reaching onboarding', :sidekiq_inline do
      user_signs_up(glm_params)

      expect_to_see_account_confirmation_page

      confirm_account

      user_signs_in

      expect_to_see_welcome_form

      fills_in_welcome_form
      click_on 'Continue'

      expect_to_see_company_form

      fill_in_company_form
      toggle_trial
      click_on 'Continue'

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
    it 'registers the user and creates a group and project reaching onboarding', :sidekiq_inline do
      user_signs_up

      expect_to_see_account_confirmation_page

      confirm_account

      user_signs_in

      expect_to_see_welcome_form

      # validate user is returned back to the specific onboarding step
      visit root_path
      expect_to_see_welcome_form

      fills_in_welcome_form
      click_on 'Continue'

      expect_to_see_company_form

      # validate user is returned back to the specific onboarding step
      visit root_path
      expect_to_see_company_form

      fill_in_company_form(trial: false)
      click_on 'Continue'

      expect_to_see_group_and_project_creation_form

      # validate user is returned back to the specific onboarding step
      visit root_path
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

  def fill_in_company_form(trial: true)
    expect(GitlabSubscriptions::CreateTrialOrLeadService).to receive(:new).with(
      user: user,
      params: company_params(trial: trial)
    ).and_return(instance_double(GitlabSubscriptions::CreateTrialOrLeadService, execute: ServiceResponse.success))

    fill_in 'company_name', with: 'Test Company'
    select '1 - 99', from: 'company_size'
    select 'United States of America', from: 'country'
    select 'Florida', from: 'state'
    fill_in 'phone_number', with: '+1234567890'
    fill_in 'website_url', with: 'https://gitlab.com'
  end

  def company_params(trial: true)
    base_params = ActionController::Parameters.new(
      company_name: 'Test Company',
      company_size: '1-99',
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

    return base_params unless trial

    base_params.merge(glm_params)
  end

  def fills_in_group_and_project_creation_form
    # The groups_and_projects_controller (on `click_on 'Create project'`) is over
    # the query limit threshold, so we have to adjust it.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/338737
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(143)

    fill_in 'group_name', with: 'Test Group'
    fill_in 'blank_project_name', with: 'Test Project'
  end

  def expect_to_apply_trial
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
  end
end
