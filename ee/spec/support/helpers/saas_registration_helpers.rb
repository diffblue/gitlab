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
    expect(page).to have_content('GitLab is better with colleagues!')
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

  def expect_to_be_see_company_form
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
end
