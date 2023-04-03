# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Sets group repository storage limit', :js, :saas, feature_category: :consumables_cost_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:admin) { create(:admin) }

  before do
    sign_in(admin)
    gitlab_enable_admin_mode_sign_in(admin)
  end

  it 'saves and displays the value' do
    visit admin_group_path(group)

    click_link 'Edit'

    fill_in 'Repository size limit', with: '250000'

    click_button('Save changes')

    click_link 'Edit'

    expect(page).to have_field('Repository size limit', with: '250000')
  end
end
