# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New Group page', :js, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:parent_group) { create(:group) }

  describe 'toggling the invite members section' do
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

  describe 'new top level group alert' do
    before do
      parent_group.add_owner(user)
      sign_in(user)
    end

    context 'when self-managed' do
      context 'when a user visits the new group page' do
        it 'does not show the new top level group alert' do
          visit new_group_path(anchor: 'create-group-pane')

          expect(page).not_to have_selector('[data-testid="new-top-level-alert"]')
        end
      end
    end

    context 'when on .com', :saas do
      context 'when a user visits the new group page' do
        it 'shows the new top level group alert' do
          visit new_group_path(anchor: 'create-group-pane')

          expect(page).to have_selector('[data-testid="new-top-level-alert"]')
        end
      end

      context 'when a user visits the new sub group page' do
        it 'does not show the new top level group alert' do
          visit new_group_path(parent_id: parent_group.id, anchor: 'create-group-pane')

          expect(page).not_to have_selector('[data-testid="new-top-level-alert"]')
        end
      end
    end
  end
end
