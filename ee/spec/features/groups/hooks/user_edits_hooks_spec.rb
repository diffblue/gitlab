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

    expect(current_path).to eq(edit_group_hook_path(group, hook))

    fill_in('URL', with: url)

    click_button('Save changes')

    expect(hook.reload.url).to eq(url)
    expect(current_path).to eq(group_hooks_path(group))
    expect(page).to have_selector('[data-testid="alert-info"]', text: 'Hook was successfully updated.')
  end
end
