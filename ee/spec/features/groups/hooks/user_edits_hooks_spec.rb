# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edits hooks' do
  let_it_be(:group) { create(:group) }
  let_it_be(:hook) { create(:group_hook, group: group) }
  let_it_be(:user) { create(:user) }

  let(:url) { 'http://example.org/new' }

  before do
    group.add_owner(user)

    sign_in(user)

    visit(group_hooks_path(group))
  end

  it 'updates existing hook' do
    click_link('Edit')

    expect(page).to have_current_path(edit_group_hook_path(group, hook), ignore_query: true)

    fill_in('URL', with: url)
    fill_in('hook[push_events_branch_filter]', with: 'notify-on-branch')
    page.check('hook[push_events]')

    click_button('Save changes')

    expect(hook.reload).to have_attributes(
      url: eq(url),
      push_events_branch_filter: eq('notify-on-branch'),
      push_events: eq(true)
    )

    expect(page).to have_current_path(group_hooks_path(group), ignore_query: true)
    expect(page).to have_selector('[data-testid="alert-info"]', text: 'Hook was successfully updated.')
  end
end
