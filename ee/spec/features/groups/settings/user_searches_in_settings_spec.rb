# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User searches group settings', :js, feature_category: :subgroups do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  context 'in Webhooks page' do
    before do
      visit group_hooks_path(group)
    end

    it_behaves_like 'can highlight results', 'Group Hooks'
  end
end
