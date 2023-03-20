# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Epic quick actions', :js, feature_category: :team_planning do
  include Features::NotesHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:epic) { create(:epic, group: group) }

  before do
    stub_licensed_features(epics: true)
    group.add_developer(user)

    sign_in(user)
    visit group_epic_path(group, epic)
  end

  context 'note with a quick action' do
    it 'previews a note with quick action' do
      preview_note('/title New Title')

      expect(page).to have_content('Changes the title to "New Title".')
    end

    it 'executes the quick action' do
      add_note('/title New Title')

      expect(page).to have_content('Changed the title to "New Title".')
      expect(epic.reload.title).to eq('New Title')

      visit group_epic_path(group, epic)

      expect(page).to have_content('New Title')
    end
  end
end
