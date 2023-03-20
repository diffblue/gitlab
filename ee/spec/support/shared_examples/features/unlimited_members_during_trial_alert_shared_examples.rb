# frozen_string_literal: true

RSpec.shared_examples_for 'unlimited members during trial alert' do
  include Features::InviteMembersModalHelpers

  it 'displays alert with Explore paid plans link' do
    visit page_path

    expect(page).to have_selector(alert_selector)
    expect(page).to have_link(text: 'Explore paid plans', href: group_billings_path(group))
  end

  it 'does not display alert after user dismisses' do
    visit page_path

    find('[data-testid="hide-unlimited-members-during-trial-alert"]').click
    wait_for_all_requests

    expect(page).not_to have_selector(alert_selector)
  end
end
