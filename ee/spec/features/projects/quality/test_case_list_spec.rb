# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Test cases', :js, feature_category: :quality_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:label) { create(:label, project: project, title: 'bug') }
  let_it_be(:test_case1) { create(:quality_test_case, project: project, author: user, created_at: 5.days.ago, updated_at: 2.days.ago, labels: [label]) }
  let_it_be(:test_case2) { create(:quality_test_case, project: project, author: user, created_at: 6.days.ago, updated_at: 2.days.ago) }
  let_it_be(:test_case3) { create(:quality_test_case, project: project, author: user, created_at: 7.days.ago, updated_at: 2.days.ago) }
  let_it_be(:test_case_archived) { create(:quality_test_case, project: project, author: user, created_at: 7.days.ago, updated_at: 2.days.ago, state: :closed) }

  before do
    project.add_developer(user)
    stub_licensed_features(quality_management: true)

    sign_in(user)
  end

  context 'test case list' do
    before do
      visit project_quality_test_cases_path(project)

      wait_for_all_requests
    end

    it 'shows tabs for state types' do
      page.within('.issuable-list-container .gl-tabs') do
        tabs = page.find_all('li.nav-item')

        expect(tabs[0]).to have_content('Open 3')
        expect(tabs[1]).to have_content('Archived 1')
        expect(tabs[2]).to have_content('All 4')
      end
    end

    it 'shows create test case button' do
      page.within('.issuable-list-container .nav-controls') do
        new_test_case = page.find('a')

        expect(new_test_case).to have_content('New test case')
        expect(new_test_case[:href]).to have_content(new_project_quality_test_case_path(project))
      end
    end

    it 'shows filtered search input' do
      page.within('.issuable-list-container .vue-filtered-search-bar-container') do
        expect(page).to have_selector('.gl-search-box-by-click')
        expect(page.find('.gl-filtered-search-term-input')[:placeholder]).to eq('Search test cases')

        expect(page).to have_selector('.sort-dropdown-container')
        page.find('.sort-dropdown-container button.gl-dropdown-toggle').click
        expect(page.find('.sort-dropdown-container')).to have_selector('li', count: 2)
      end
    end

    it 'shows filter tokens author and label' do
      page.within('.vue-filtered-search-bar-container .gl-search-box-by-click') do
        page.find('input').click

        expect(page.find('.gl-filtered-search-suggestion-list')).to have_selector('li', count: 2)
        expect(page.find('.gl-filtered-search-suggestion-list li:nth-child(1)')).to have_content('Author')
        expect(page.find('.gl-filtered-search-suggestion-list li:nth-child(2)')).to have_content('Label')
      end
    end

    context 'open tab' do
      it 'shows list of all open test cases' do
        page.within('.issuable-list-container .issuable-list') do
          expect(page).to have_selector('li.issue', count: 3)
        end
      end

      it 'shows test cases title and metadata' do
        page.within('.issuable-list-container .issuable-list li.issue', match: :first) do
          expect(page).to have_link(test_case1.title)
          expect(page).to have_text("##{test_case1.iid}")
          expect(page).to have_link(label.title, href: "?label_name[]=#{label.title}")
          expect(page).to have_text("created 5 days ago by #{user.name}")
          expect(page).to have_text('updated 2 days ago')
        end
      end
    end

    context 'archived tab' do
      before do
        find(:link, text: 'Archived').click

        wait_for_requests
      end

      it 'shows list of all archived test cases' do
        page.within('.issuable-list-container .issuable-list') do
          expect(page).to have_selector('li.issue', count: 1)
        end
      end
    end

    context 'all tab' do
      before do
        find(:link, text: 'All').click

        wait_for_requests
      end

      it 'shows list of all test cases' do
        page.within('.issuable-list-container .issuable-list') do
          expect(page).to have_selector('li.issue', count: 4)
        end
      end
    end
  end
end
