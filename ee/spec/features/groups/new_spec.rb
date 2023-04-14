# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New Group page', feature_category: :subgroups do
  describe 'toggling the invite members section', :js do
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
      visit new_group_path
      click_link 'Create group'
    end

    describe 'when selecting options from the "Who will be using this group?" question' do
      it 'toggles the invite members section' do
        expect(page).to have_content('Invite Members')
        choose 'Just me'
        expect(page).not_to have_content('Invite Members')
        choose 'My company or team'
        expect(page).to have_content('Invite Members')
      end
    end
  end
end
