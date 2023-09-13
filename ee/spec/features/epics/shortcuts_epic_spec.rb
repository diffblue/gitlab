# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Epic shortcuts', :js, feature_category: :portfolio_management do
  include ContentEditorHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:label) { create(:group_label, group: group, title: 'bug') }
  let(:note_text) { 'I got this!' }

  let(:markdown) do
    <<-MARKDOWN.strip_heredoc
    This is a task list:

    - [ ] Incomplete entry 1
    MARKDOWN
  end

  let(:epic) { create(:epic, group: group, title: 'make tea', description: markdown) }

  before do
    group.add_developer(user)
    stub_licensed_features(epics: true)
    sign_in(user)

    visit group_epic_path(group, epic)

    # Ensure that the shortcuts code has initialized
    find('.js-awards-block')
  end

  describe 'pressing "l"' do
    it "opens labels dropdown for editing" do
      find('body').native.send_key('l')

      expect(find('.js-labels-block')).to have_selector('[data-testid="labels-select-dropdown-contents"]')
    end
  end

  describe 'pressing "r"' do
    before do
      create(:note, noteable: epic, note: note_text)
      visit group_epic_path(group, epic)

      # Wait again for shortcuts code to be initialize
      find('.js-awards-block')
    end

    it "quotes the selected text" do
      close_rich_text_promo_popover_if_present

      # This functionality now requires that the reply component has already been opened.
      click_on('Reply to comment')

      note = find('.note-text')
      highlight_content(note)

      find('body').native.send_key('r')

      expect(page).to have_field('note_note', with: "> #{note_text}\n\n", type: 'textarea')
    end
  end

  describe 'pressing "e"' do
    it "starts editing mode for epic" do
      find('body').native.send_key('e')

      expect(find('.detail-page-description')).to have_selector('form input#issuable-title')
      expect(find('.detail-page-description')).to have_selector('form textarea#issue-description')
    end
  end
end
