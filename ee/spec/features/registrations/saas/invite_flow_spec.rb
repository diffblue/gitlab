# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'SaaS registration from an invite', :js, :saas_registration, :sidekiq_inline, feature_category: :onboarding do
  it 'registers the user and sends them to the group activity page' do
    new_user = build(:user, name: 'Registering User', email: user_email)
    group = create(:group, name: 'Test Group')

    registers_from_invite(user: new_user, group: group)

    ensure_onboarding { expect_to_see_welcome_form_for_invites }
    expect_to_send_iterable_request(invite: true)

    fill_in_welcome_form
    click_on 'Get started!'

    expect_to_be_on_activity_page_for(group)
    ensure_onboarding_is_finished
  end

  it 'registers the user with multiple invites and sends them to the last group activity page' do
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

    ensure_onboarding { expect_to_see_welcome_form_for_invites }
    expect_to_send_iterable_request(invite: true)

    fill_in_welcome_form
    click_on 'Get started!'

    expect(page).to have_current_path(activity_group_path(group), ignore_query: true)
    ensure_onboarding_is_finished
  end

  def registers_from_invite(user:, group:)
    invitation = create(
      :group_member,
      :invited,
      :developer,
      invite_email: user.email,
      source: group
    )

    visit invite_path(invitation.raw_invite_token, invite_type: Emails::Members::INITIAL_INVITE)

    fill_in_sign_up_form(user)
  end

  def fill_in_welcome_form
    select 'Software Developer', from: 'user_role'
    select 'A different reason', from: 'user_registration_objective'
    fill_in 'Why are you signing up? (optional)', with: 'My reason'
  end
end
