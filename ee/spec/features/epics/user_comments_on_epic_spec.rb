# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User comments on epic', :js, feature_category: :portfolio_management do
  include Features::NotesHelpers

  let_it_be(:user) { create(:user, name: '💃speciąl someone💃', username: 'someone.special') }
  let_it_be(:group) { create(:group) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group) }

  before_all do
    group.add_maintainer(user)
  end

  before do
    stub_licensed_features(epics: true)
    sign_in(user)

    visit group_epic_path(group, epic)
  end

  context 'when adding comments' do
    it 'adds comment' do
      content = 'XML attached'

      add_note(content)

      page.within('.note') do
        expect(page).to have_content(content)
      end

      page.within('.js-main-target-form') do
        find('.error-alert', visible: false)
      end
    end

    it 'links an issuable' do
      fill_in 'Comment', with: "#{epic2.to_reference(full: true)}+"

      page.within('.new-note') do
        click_button("Preview")
        wait_for_requests

        within('.md-preview-holder') do
          expect(page).to have_link(
            epic2.title,
            href: /#{epic_path(epic2)}/
          )
        end
      end
    end
  end
end
