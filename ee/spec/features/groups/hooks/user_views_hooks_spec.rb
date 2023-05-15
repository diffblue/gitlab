# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User views hooks", feature_category: :webhooks do
  let_it_be(:group) { create(:group) }
  let_it_be(:hook) { create(:group_hook, group: group) }
  let_it_be(:user) { create(:user) }

  before do
    group.add_owner(user)

    sign_in(user)

    visit(group_hooks_path(group))
  end

  it { expect(page).to have_content(hook.url) }
end
