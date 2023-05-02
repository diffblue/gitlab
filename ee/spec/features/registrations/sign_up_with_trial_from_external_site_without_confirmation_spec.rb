# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sign up with trial from external site without confirmation', :saas, :js,
feature_category: :onboarding do
  let_it_be(:glm_params) do
    { glm_source: 'some_source', glm_content: 'some_content' }
  end

  before do
    stub_application_setting(require_admin_approval_after_user_signup: false)
    stub_feature_flags(arkose_labs_signup_challenge: false)

    # The groups_and_projects_controller (on `click_on 'Create project'`) is over
    # the query limit threshold, so we have to adjust it.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/340302
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(159)

    stub_request(:post, "#{EE::SUBSCRIPTIONS_URL}/trials")
  end

  it 'passes glm parameters until user is onboarded' do
    user = build_stubbed(:user)
    glm_params = { glm_source: 'some_source', glm_content: 'some_content' }

    visit new_user_registration_path(glm_params)

    fill_in 'new_user_first_name', with: user.first_name
    fill_in 'new_user_last_name', with: user.last_name
    fill_in 'new_user_username', with: user.username
    fill_in 'new_user_email', with: user.email
    fill_in 'new_user_password', with: user.password
    wait_for_all_requests

    click_button 'Register'

    select 'Software Developer', from: 'user_role'
    choose 'My company or team'
    choose 'Create a new project'
    click_button 'Continue'

    expect(Gitlab::SubscriptionPortal::Client)
      .to receive(:generate_trial)
      .with(hash_including(glm_params))
      .and_call_original

    fill_in 'company_name', with: 'Company name'
    select '1 - 99', from: 'company_size'
    select 'Australia', from: 'country'
    find('button.gl-toggle').click
    click_button 'Continue'

    fill_in 'group_name', with: 'Group name'
    fill_in 'blank_project_name', with: 'Project name'
    click_button 'Create project'

    expect(page).to have_content('Get started with GitLab')
    expect(page).to have_content("Ok, let's go")
  end
end
