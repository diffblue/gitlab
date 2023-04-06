# frozen_string_literal: true

RSpec.shared_examples_for 'unlimited members during trial alert' do
  include Features::InviteMembersModalHelpers

  it 'displays alert with only Explore paid plans link on members page' do
    visit members_page_path

    expect(page).to have_selector(alert_selector)
    expect(page).to have_link(text: 'Explore paid plans', href: group_billings_path(group))
    expect(page).not_to have_button('Invite more members')
  end

  it 'displays alert with Explore paid plans link and Invite more members button on other pages' do
    visit page_path

    expect(page).to have_selector(alert_selector)
    expect(page).to have_link(text: 'Explore paid plans', href: group_billings_path(group))
    expect(page).to have_button('Invite more members')

    click_button 'Invite more members'

    expect(page).to have_selector(invite_modal_selector)
  end

  it 'does not display alert after user dismisses' do
    visit page_path

    find('[data-testid="hide-unlimited-members-during-trial-alert"]').click

    wait_for_all_requests

    expect(page).to have_content('Subgroups and projects').or have_content('Project information')
    expect(page).not_to have_selector(alert_selector)
  end
end
