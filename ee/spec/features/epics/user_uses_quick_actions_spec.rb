# frozen_string_literal: true

require 'spec_helper'

# Epics quick actions functionality are covered on unit test specs. These
# are added just to test frontend features at least once, before adding more
# specs to this file please take into account if there is any behaviour
# different from the current ones that needs to be tested.
RSpec.describe 'Epics > User uses quick actions', :js, feature_category: :portfolio_management do
  include Features::NotesHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:epic_1) { create(:epic, group: group) }

  before do
    stub_licensed_features(epics: true, subepics: true)
    group.add_reporter(user)
    sign_in(user)
  end

  context 'on epic note' do
    it 'applies quick action' do
      epic_2 = create(:epic, group: group)
      visit group_epic_path(group, epic_2)
      wait_for_requests

      add_note("new note \n\n/parent_epic #{epic_1.to_reference}")

      wait_for_requests
      expect(epic_2.reload.parent).to eq(epic_1)
      expect(page).to have_content("added epic #{epic_1.to_reference} as parent epic")
    end
  end

  context 'on epic form' do
    it 'applies quick action' do
      epic_title = 'New epic with parent'
      visit new_group_epic_path(group)

      find('#epic-title').native.send_keys(epic_title)
      find('#epic-description').native.send_keys("With parent \n\n/parent_epic #{epic_1.to_reference}")
      click_button 'Create epic'
      wait_for_requests

      expect(group.epics.find_by_title(epic_title).parent).to eq(epic_1)
      expect(page).to have_content("added epic #{epic_1.to_reference} as parent epic")
    end
  end
end
