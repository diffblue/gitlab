# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SaaS registration from an invite', :js, :saas_registration, feature_category: :onboarding do
  it 'registers the user and sends them to the group activity page', :sidekiq_inline do
    new_user = build(:user, name: 'Registering User', email: user_email)
    group = create(:group, name: 'Test Group')

    registers_from_invite(user: new_user, group: group)

    ensure_onboarding { expect_to_see_welcome_form_without_join_project_question }
    expect_to_send_iterable_request

    fill_in_welcome_form
    click_on 'Get started!'

    expect_to_be_on_activity_page_for(group)
    ensure_onboarding_is_finished
  end

  it 'registers the user with multiple invites and sends them to the root page', :sidekiq_inline do
    new_user = build(:user, name: 'Registering User', email: user_email)
    group = create(:group, name: 'Test Group')

    create(
      :group_member,
      :invited,
      :developer,
      invite_email: new_user.email,
      source: create(:group, name: 'Another Test Group')
    )

    registers_from_invite(user: new_user, group: group)

    ensure_onboarding { expect_to_see_welcome_form_without_join_project_question }
    expect_to_send_iterable_request

    fill_in_welcome_form
    click_on 'Get started!'

    expect(page).to have_current_path(root_path)
    ensure_onboarding_is_finished
  end

  it 'registers the user and sends them to the tasks to be done page', :sidekiq_inline do
    new_user = build(:user, name: 'Registering User', email: user_email)
    group = create(:group, name: 'Test Group')

    allow_task_to_be_done
    registers_from_invite(user: new_user, group: group, tasks_to_be_done: [:ci, :code])

    ensure_onboarding { expect_to_see_welcome_form_without_join_project_question }
    expect_to_send_iterable_request

    fill_in_welcome_form
    click_on 'Get started!'

    expect_to_be_on_issues_dashboard_page_for(new_user)
    ensure_onboarding_is_finished
  end

  def registers_from_invite(user:, group:, tasks_to_be_done: [])
    invitation = create(
      :group_member,
      :invited,
      :developer,
      invite_email: user.email,
      source: group,
      tasks_to_be_done: tasks_to_be_done
    )

    visit invite_path(invitation.raw_invite_token, invite_type: Emails::Members::INITIAL_INVITE)

    fill_in 'First name', with: user.first_name
    fill_in 'Last name', with: user.last_name
    fill_in 'Username', with: user.username
    fill_in 'Email', with: user.email
    fill_in 'Password', with: user.password

    wait_for_all_requests

    click_button 'Register'
  end

  def fill_in_welcome_form
    select 'Software Developer', from: 'user_role'
    select 'A different reason', from: 'user_registration_objective'
    fill_in 'Why are you signing up? (optional)', with: 'My reason'
  end

  def allow_task_to_be_done
    allow(TasksToBeDone::CreateWorker).to receive(:perform_async)
  end

  def expect_to_see_welcome_form_without_join_project_question
    expect(page).to have_content('Welcome to GitLab, Registering!')

    page.within(welcome_form_selector) do
      expect(page).not_to have_content('What would you like to do?')
    end
  end

  def expect_to_be_on_activity_page_for(group)
    expect(page).to have_current_path(activity_group_path(group), ignore_query: true)
    expect(page).to have_content('You have been granted Developer access to group Test Group')
  end

  def expect_to_be_on_issues_dashboard_page_for(user)
    expect(page).to have_current_path(issues_dashboard_path, ignore_query: true)
    expect(page).to have_content("Assignee = #{user.name}")
  end
end
