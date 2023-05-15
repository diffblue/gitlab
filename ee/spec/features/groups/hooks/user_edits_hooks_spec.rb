# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edits hooks', feature_category: :webhooks do
  let_it_be(:group) { create(:group) }
  let_it_be(:hook) { create(:group_hook, group: group) }
  let_it_be(:user) { create(:user) }

  let(:url) { 'http://example.org/new' }

  before do
    group.add_owner(user)

    sign_in(user)

    visit(group_hooks_path(group))
  end

  it 'shows dom element for vue', :js do
    click_link('Edit')

    expect(page).to have_content('Push events')
  end
end
