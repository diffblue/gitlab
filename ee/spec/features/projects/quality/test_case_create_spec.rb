# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Test cases', :js, feature_category: :quality_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:label1) { create(:label, project: project, title: 'bug') }
  let_it_be(:label2) { create(:label, project: project, title: 'enhancement') }
  let_it_be(:label3) { create(:label, project: project, title: 'documentation') }

  before do
    project.add_developer(user)
    stub_licensed_features(quality_management: true)

    sign_in(user)
  end

  context 'test case create form' do
    before do
      visit new_project_quality_test_case_path(project)

      wait_for_requests
    end

    it 'shows page title, title, description and label input fields' do
      page.within('.issuable-create-container') do
        expect(page.find('.page-title')).to have_content('New test case')
      end

      page.within('.issuable-create-container form') do
        form_fields = page.find_all('.row')

        expect(form_fields[0].find('label')).to have_content('Title')
        expect(form_fields[0]).to have_selector('input#issuable-title')

        expect(form_fields[1].find('label')).to have_content('Description')
        expect(form_fields[1]).to have_selector('.js-vue-markdown-field')

        expect(form_fields[2].find('label')).to have_content('Labels')
        expect(form_fields[2]).to have_selector('.labels-select-wrapper')
      end
    end

    it 'shows labels and footer actions within labels dropdown' do
      page.within('.issuable-create-container form .labels-select-wrapper') do
        page.find('.js-dropdown-button').click

        wait_for_requests

        expect(page.find('.js-labels-list .dropdown-content')).to have_selector('li', count: 3)
        expect(page.find('.js-labels-list .dropdown-footer')).to have_selector('li', count: 2)
      end
    end

    it 'shows page actions' do
      page.within('.issuable-create-container .footer-block') do
        expect(page.find('button')).to have_content('Submit test case')
        expect(page.find('a')).to have_content('Cancel')
      end
    end

    it 'creates a test case on saving form' do
      title = 'Sample title'
      description = 'Sample _test case_ description.'

      page.within('.issuable-create-container form') do
        form_fields = page.find_all('.row')

        form_fields[0].find('input#issuable-title').native.send_keys title
        form_fields[1].find('textarea#issuable-description').native.send_keys description
        form_fields[2].find('.js-dropdown-button').click

        wait_for_requests

        form_fields[2].find_all('.js-labels-list .dropdown-content li')[0].click
      end

      click_button 'Submit test case'

      wait_for_requests

      expect(page).to have_selector('.content-wrapper .project-test-cases')
    end
  end
end
