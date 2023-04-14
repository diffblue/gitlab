# frozen_string_literal: true

module SaasRegistrationHelpers
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

  def glm_params
    {
      glm_source: 'some_source',
      glm_content: 'some_content'
    }
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

  def welcome_form_selector
    '[data-testid="welcome-form"]'
  end

  def fills_in_group_and_project_creation_form
    # The groups_and_projects_controller (on `click_on 'Create project'`) is over
    # the query limit threshold, so we have to adjust it.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/404805
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(157)

    fill_in 'group_name', with: 'Test Group'
    fill_in 'blank_project_name', with: 'Test Project'
  end

  def fills_in_group_and_project_creation_form_with_trial
    fills_in_group_and_project_creation_form

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

  def company_params(trial: true, glm: true)
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

    return base_params unless glm

    base_params.merge(glm_params)
  end
end
