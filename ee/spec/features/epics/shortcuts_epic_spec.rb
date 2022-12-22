# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Epic shortcuts', :js, feature_category: :portfolio_management do
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
      wait_for_requests
    end

    it "quotes the selected text", quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/11057' do
      select_element('.note-text')
      find('body').native.send_key('r')

      expect(find('.js-main-target-form .js-vue-comment-form').value).to include(note_text)
    end
  end

  describe 'pressing "e"' do
    it "starts editing mode for epic", quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/299523' do
      find('body').native.send_key('e')

      expect(find('.detail-page-description')).to have_selector('form input#issuable-title')
      expect(find('.detail-page-description')).to have_selector('form textarea#issue-description')
    end
  end
end
