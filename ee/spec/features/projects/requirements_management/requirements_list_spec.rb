# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Requirements list', :js, feature_category: :requirements_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:user_guest) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:public_project) { create(:project, :public) }
  let_it_be(:requirement1) { create(:work_item, :requirement, project: project, title: 'Some requirement-1', description: 'Sample description', author: user, created_at: 5.days.ago, updated_at: 2.days.ago).requirement }
  let_it_be(:requirement2) { create(:work_item, :requirement, project: project, title: 'Some requirement-2', description: 'Sample description', author: user, created_at: 6.days.ago, updated_at: 2.days.ago).requirement }
  let_it_be(:requirement3) { create(:work_item, :requirement, project: project, title: 'Some requirement-3', description: 'Sample description', author: user, created_at: 7.days.ago, updated_at: 2.days.ago).requirement }
  let_it_be(:requirement_archived) { create(:work_item, :requirement, project: project, title: 'Some requirement-3', description: 'Sample description', state: :closed, author: user, created_at: 8.days.ago, updated_at: 2.days.ago).requirement }

  def create_requirement(title)
    page.within('.nav-controls') do
      find('button.js-new-requirement').click
    end

    page.within('.requirement-form-drawer') do
      find('input#issuable-title').native.send_keys title
      find('button.js-requirement-save').click

      wait_for_all_requests
    end
  end

  before do
    stub_licensed_features(requirements: true)
    project.add_maintainer(user)
    project.add_guest(user_guest)

    sign_in(user)
  end

  context 'when requirements exist for the project' do
    before do
      visit project_requirements_management_requirements_path(project)

      wait_for_requests
    end

    it 'shows the requirements in the navigation sidebar' do
      expect(first('.nav-sidebar .active .sidebar-sub-level-items')).to have_content('Requirements')
    end

    it 'shows requirements tabs for each status type' do
      page.within('.gl-tabs') do
        expect(page).to have_selector('li > a[data-testid="state-opened"]')
        expect(find('li > a[data-testid="state-opened"] .badge')).to have_content('3')

        expect(page).to have_selector('li > a[data-testid="state-archived"]')
        expect(find('li > a[data-testid="state-archived"] .badge')).to have_content('1')

        expect(page).to have_selector('li > a[data-testid="state-all"]')
        expect(find('li > a[data-testid="state-all"] .badge')).to have_content('4')
      end
    end

    it 'shows filtered search input' do
      page.within('.requirements-list-container .vue-filtered-search-bar-container') do
        expect(page).to have_selector('.gl-search-box-by-click')
        expect(page.find('.gl-filtered-search-term-input')[:placeholder]).to eq('Search requirements')

        expect(page).to have_selector('.sort-dropdown-container')
        page.find('.sort-dropdown-container button.gl-dropdown-toggle').click
        expect(page.find('.sort-dropdown-container')).to have_selector('li', count: 2)
      end
    end

    context 'filtered search input' do
      it 'shows filter tokens author and status' do
        page.within('.vue-filtered-search-bar-container .gl-search-box-by-click') do
          page.find('input').click

          expect(page.find('.gl-filtered-search-suggestion-list')).to have_selector('li', count: 2)
          page.within('.gl-filtered-search-suggestion-list') do
            expect(page.find('li:nth-child(1)')).to have_content('Author')
            expect(page.find('li:nth-child(2)')).to have_content('Status')
          end
        end
      end

      it 'shows options `satisfied`, `failed` and `missing` for status token' do
        page.within('.vue-filtered-search-bar-container .gl-search-box-by-click') do
          page.find('input').click
          page.find('.gl-filtered-search-suggestion-list li:nth-child(2)').click

          expect(page.find('.gl-filtered-search-suggestion-list')).to have_selector('li', count: 3)
          page.within('.gl-filtered-search-suggestion-list') do
            expect(page.find('li:nth-child(1)')).to have_content('Satisfied')
            expect(page.find('li:nth-child(2)')).to have_content('Failed')
            expect(page.find('li:nth-child(3)')).to have_content('Missing')
          end
        end
      end
    end

    context 'new requirement' do
      it 'shows requirement create form when "New requirement" button is clicked' do
        page.within('.nav-controls') do
          find('button.js-new-requirement').click
        end

        page.within('.requirements-list-container') do
          expect(page).to have_selector('.requirement-form-drawer')
        end
      end

      it 'disables new requirement button while create form is open' do
        page.within('.nav-controls') do
          find('button.js-new-requirement').click
          expect(find('button.js-new-requirement')[:disabled]).to eq "true"
        end
      end

      it 'creates new requirement' do
        requirement_title = 'Foobar'

        create_requirement(requirement_title)

        page.within('.requirements-list-container') do
          expect(page).to have_selector('li.requirement', count: 4)
          page.within('.requirements-list li.requirement', match: :first) do
            expect(page.find('.issue-title-text')).to have_content(requirement_title)
          end
        end
      end

      it 'updates requirements count in nav sidebar and opened and all tab badges' do
        page.within('.gl-tabs') do
          expect(find('li > a[data-testid="state-opened"] .badge')).to have_content('3')
          expect(find('li > a[data-testid="state-all"] .badge')).to have_content('4')
        end

        create_requirement('Foobar')

        page.within('.gl-tabs') do
          expect(find('li > a[data-testid="state-opened"] .badge')).to have_content('4')
          expect(find('li > a[data-testid="state-all"] .badge')).to have_content('5')
        end
      end
    end

    context 'open tab' do
      it 'shows button "New requirement"' do
        page.within('.nav-controls') do
          expect(page).to have_selector('button.js-new-requirement')
          expect(find('button.js-new-requirement')).to have_content('New requirement')
        end
      end

      it 'shows list of all open requirements' do
        page.within('.requirements-list-container .requirements-list') do
          expect(page).to have_selector('li.requirement', count: 3)
        end
      end

      it 'shows title, metadata and actions within each requirement item' do
        page.within('.requirements-list li.requirement', match: :first) do
          expect(page).to have_content("##{requirement1.iid}")
          expect(page).to have_content("REQ-#{requirement1.requirement_issue.iid}")
          expect(page.find('.issue-title-text')).to have_content(requirement1.title)
          expect(page.find('.issuable-authored')).to have_content('created 5 days ago by')
          expect(page.find('.author')).to have_content(user.name)
          expect(page.find('.controls')).to have_selector('li.requirement-edit button[title="Edit"]')
          expect(page.find('.controls')).to have_selector('li.requirement-archive button[title="Archive"]')
          expect(page.find('.issuable-updated-at')).to have_content('updated 2 days ago')
        end
      end

      it 'shows title and description along with edit button in drawer' do
        find('.requirements-list li.requirement', match: :first).click

        page.within('.requirement-form-drawer') do
          expect(page.find('.title-container')).to have_content(requirement1.title)
          expect(page.find('.title-container')).to have_selector('button.btn-edit')
          expect(page.find('.description')).to have_content(requirement1.description)
        end
      end

      it 'shows edit form when edit button is clicked for a requirement' do
        page.within('.requirements-list li.requirement', match: :first) do
          find('li.requirement-edit button[title="Edit"]').click
        end

        page.within('.requirement-form-drawer') do
          expect(page.find('.gl-drawer-header', match: :first)).to have_content("##{requirement1.iid}")
          expect(page.find('input#issuable-title')['value']).to have_content(requirement1.title)
          expect(page.find('textarea#issuable-description')['value']).to have_content(requirement1.description)
          expect(page.find('input[type="checkbox"]')['checked']).to eq(requirement1.last_test_report_state)
          expect(page.find('.js-requirement-save')).to have_content('Save changes')
        end
      end

      it 'updates requirement using edit form' do
        requirement_title = 'Foobar'
        requirement_description = 'Baz'

        page.within('.requirements-list li.requirement', match: :first) do
          find('li.requirement-edit button[title="Edit"]').click
        end

        page.within('.requirement-form-drawer') do
          find('input#issuable-title').native.send_keys requirement_title
          find('textarea#issuable-description').native.send_keys requirement_description
          find('input[type="checkbox"]').click

          click_button 'Save changes'

          wait_for_all_requests
        end

        page.within('.requirements-list li.requirement', match: :first) do
          expect(page.find('.issue-title-text')).to have_content(requirement_title)
          expect(page.find('.requirement-status-badge')).to have_content('satisfied')
        end
      end

      it 'archives a requirement' do
        page.within('.requirements-list li.requirement', match: :first) do
          find('li.requirement-archive button[title="Archive"]').click

          wait_for_requests
        end

        expect(page.find('.requirements-list-container')).to have_selector('li.requirement', count: 2)
        page.within('.gl-tabs') do
          expect(find('li > a[data-testid="state-opened"] .badge')).to have_content('2')
          expect(find('li > a[data-testid="state-archived"] .badge')).to have_content('2')
        end
      end
    end

    context 'archived tab' do
      before do
        find('li > a[data-testid="state-archived"]').click

        wait_for_requests
      end

      it 'does not show button "New requirement"' do
        expect(page).not_to have_selector('.nav-controls button.js-new-requirement')
      end

      it 'shows list of all archived requirements' do
        page.within('.requirements-list-container .requirements-list') do
          expect(page).to have_selector('li.requirement', count: 1)
        end
      end

      it 'shows title, metadata and actions within each requirement item' do
        page.within('.requirements-list li.requirement', match: :first) do
          expect(page).to have_content("##{requirement_archived.iid}")
          expect(page).to have_content("REQ-#{requirement_archived.requirement_issue.iid}")
          expect(page.find('.issue-title-text')).to have_content(requirement_archived.title)
          expect(page.find('.issuable-authored')).to have_content('created 1 week ago by')
          expect(page.find('.author')).to have_content(user.name)
          expect(page.find('.controls')).to have_selector('li.requirement-reopen button', text: 'Reopen')
          expect(page.find('.issuable-updated-at')).to have_content('updated 2 days ago')
        end
      end

      it 'reopens a requirement' do
        page.within('.requirements-list li.requirement', match: :first) do
          find('li.requirement-reopen button').click

          wait_for_requests
        end

        expect(page.find('.requirements-list-container')).to have_selector('li.requirement', count: 0)
        page.within('.gl-tabs') do
          expect(find('li > a[data-testid="state-opened"] .badge')).to have_content('4')
          expect(find('li > a[data-testid="state-archived"] .badge')).to have_content('0')
        end
      end
    end

    context 'all tab' do
      before do
        find('li > a[data-testid="state-all"]').click

        wait_for_requests
      end

      it 'does not show button "New requirement"' do
        expect(page).not_to have_selector('.nav-controls button.js-new-requirement')
      end

      it 'shows list of all requirements' do
        page.within('.requirements-list-container .requirements-list') do
          expect(page).to have_selector('li.requirement', count: 4)
        end
      end
    end

    context 'filtered search' do
      it 'shows filtered search input field' do
        page.within('.vue-filtered-search-bar-container') do
          expect(page).to have_selector('input.gl-filtered-search-term-input')
        end
      end

      it 'shows sort dropdown' do
        page.within('.vue-filtered-search-bar-container') do
          expect(page).to have_selector('.gl-dropdown button.gl-dropdown-toggle')
          expect(page).to have_selector('.gl-dropdown ul.dropdown-menu', visible: false)
        end
      end
    end
  end

  context 'when accessing project as guest user' do
    before do
      sign_in(user_guest)
      visit project_requirements_management_requirements_path(project)

      wait_for_requests
    end

    it 'open tab does not show button "New requirement"' do
      expect(page).not_to have_selector('.nav-controls button.js-new-requirement')
    end
  end

  context 'when accessing project as logged out user' do
    before do
      sign_out user

      visit project_requirements_management_requirements_path(public_project)
      wait_for_requests
    end

    it 'renders the empty state' do
      expect(page).to have_selector('.requirements-empty-state-container')
    end
  end
end
