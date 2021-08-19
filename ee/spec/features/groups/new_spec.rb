# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New Group page' do
  describe 'toggling the invite members section', :js do
    before do
      sign_in(create(:user))
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
