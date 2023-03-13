# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Related Epics', :js, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:epic1) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group) }
  let_it_be(:epic3) { create(:epic, group: group) }

  def visit_epic(related_epics: true)
    group.add_developer(user)
    stub_licensed_features(epics: true, related_epics: related_epics)
    sign_in(user)
    visit group_epic_path(group, epic1)

    wait_for_requests
  end

  def open_add_epic_form
    page.within('.related-issues-block') do
      click_button 'Add a related epic'
    end
  end

  def add_epic(epic, relationship)
    page.within('.js-add-related-issues-form-area') do
      page.find('#add-related-issues-form-input').native.send_keys("&#{epic.iid} ")

      page.find("input[value='#{relationship}']").click

      click_button 'Add'

      wait_for_requests
    end
  end

  before do
    visit_epic
  end

  describe 'epic body section' do
    it 'user can view related epics section under epic description', :aggregate_failures do
      page.within('#related-issues') do
        card_title = page.find('.card-title')
        card_body = page.find('.linked-issues-card-body ')
        expect(card_title).to have_content('Linked epics')
        expect(card_body).to have_link('', href: '/help/user/group/epics/linked_epics')
        card = page.find('.gl-card')
        expect(card).to have_selector('button', text: 'Add')
      end
    end
  end

  describe 'related epics add epic form' do
    before do
      open_add_epic_form
    end

    it 'user can view category selection radio inputs', :aggregate_failures do
      page.within('.js-add-related-issues-form-area') do
        expect(page.find('label[for="linked-issue-type-radio"]')).to have_content('The current epic')

        page.within('#linked-issue-type-radio') do
          [
            'relates to',
            'blocks',
            'is blocked by'
          ].each_with_index do |category, index|
            expect(page.find(".gl-form-radio:nth-child(#{index + 1})")).to have_content(category)
          end
        end
      end
    end

    it 'user can view epic input field', :aggregate_failures do
      page.within('.js-add-related-issues-form-area') do
        expect(page.find('p')).to have_content('the following epics')
        expect(page).to have_selector('.add-issuable-form-input-wrapper')
      end
    end

    it 'epic input field can autocomplete epics when `&` is input', :aggregate_failures do
      page.within('.js-add-related-issues-form-area') do
        page.find('#add-related-issues-form-input').native.send_keys('&')
      end

      wait_for_requests

      expect(page).to have_selector('#at-view-epics .atwho-view-ul li', count: 3)
      [epic3, epic2, epic1].each_with_index do |epic, index|
        expect(page.find("#at-view-epics li:nth-child(#{index + 1})")).to have_content("&#{epic.iid} #{epic.title}")
      end
    end

    it 'epic input field does not autocomplete issues when `#` is input', :aggregate_failures do
      page.within('.js-add-related-issues-form-area') do
        page.find('#add-related-issues-form-input').native.send_keys('#')
      end

      wait_for_requests

      expect(page).not_to have_selector('#at-view-issues .atwho-view-ul li', count: 1)
    end

    it 'user can view list of added epics as tokens within input field', :aggregate_failures do
      page.within('.js-add-related-issues-form-area .add-issuable-form-input-wrapper') do
        page.find('#add-related-issues-form-input').native.send_keys("&#{epic1.iid} ")

        expect(page.find('.issue-token')).to have_content("&#{epic1.iid}")
        expect(page).to have_selector('button.issue-token-remove-button')
      end
    end
  end

  describe 'related epics list' do
    it 'user can add an epic with selected relationship type', :aggregate_failures do
      relationship_types = %w[blocks is_blocked_by relates_to]
      list_headings = ['Blocks', 'Is blocked by', 'Relates to']

      relationship_types.each_with_index do |relationship, index|
        temp_epic = create(:epic, group: group)

        open_add_epic_form

        add_epic(temp_epic, relationship)

        page.within("div[data-link-type='#{relationship}']") do
          expect(page.find('h4')).to have_content(list_headings[index])
          expect(page.find('ul.related-items-list')).to have_selector('li', count: 1)
          expect(page.find('ul.related-items-list li')).to have_content(temp_epic.title)
          expect(page.find('ul.related-items-list li')).to have_selector('button.js-issue-item-remove-button')
        end
      end
    end

    it 'user can remove an epic from the list', :aggregate_failures do
      open_add_epic_form

      add_epic(epic2, 'relates_to')

      page.within('div[data-link-type="relates_to"]') do
        page.find('button.js-issue-item-remove-button').click
      end

      wait_for_requests

      expect(page).not_to have_selector('div[data-link-type="relates_to"]')
    end
  end

  describe 'when related epics is not supported by license' do
    before do
      visit_epic(related_epics: false)
    end

    it 'user can not view related epics section under epic description', :aggregate_failures do
      page.within('.js-epic-container') do
        expect(page).not_to have_selector('#related-issues')
      end
    end
  end
end
