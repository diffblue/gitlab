# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Test cases', :js, feature_category: :quality_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:label_bug) { create(:label, project: project, title: 'bug') }
  let_it_be(:label_doc) { create(:label, project: project, title: 'documentation') }
  let_it_be(:test_case) { create(:quality_test_case, project: project, author: user, description: 'Sample description', created_at: 5.days.ago, updated_at: 2.days.ago, labels: [label_bug]) }

  before do
    project.add_developer(user)
    stub_licensed_features(quality_management: true)

    sign_in(user)
  end

  context 'test case page' do
    before do
      visit project_quality_test_case_path(project, test_case)

      wait_for_all_requests
    end

    context 'header' do
      it 'shows status, created date and author' do
        page.within('.test-case-container .detail-page-header-body') do
          expect(page.find('.issuable-status-badge')).to have_content('Open')
          expect(page.find('.issuable-meta')).to have_content('Test case created 5 days ago')
          expect(page.find('.issuable-meta')).to have_link(user.name)
        end
      end

      it 'shows action buttons' do
        page.within('.test-case-container .detail-page-header') do
          expect(page).to have_selector('.dropdown', visible: false)
          expect(page).to have_button('Archive test case')
          expect(page).to have_link('New test case', href: new_project_quality_test_case_path(project))
        end
      end

      it 'archives test case' do
        page.within('.test-case-container') do
          click_button 'Archive test case'

          wait_for_requests

          expect(page.find('.issuable-status-badge')).to have_content('Archived')
          expect(page).to have_button('Reopen test case')
        end
      end
    end

    context 'body' do
      it 'shows title, description and edit button' do
        page.within('.test-case-container .issuable-details') do
          expect(page.find('.title')).to have_content(test_case.title)
          expect(page.find('.description')).to have_content(test_case.description)
          expect(page).to have_selector('button.js-issuable-edit')
        end
      end

      it 'makes title and description editable on edit click' do
        find('.test-case-container .issuable-details .js-issuable-edit').click

        page.within('.test-case-container .issuable-details form') do
          expect(page.find('input#issuable-title').value).to eq(test_case.title)
          expect(page.find('textarea#issuable-description').value).to eq(test_case.description)
          expect(page).to have_button('Save changes')
          expect(page).to have_button('Cancel')
        end
      end

      it 'enters into zen mode when clicking on zen mode button' do
        page.within('.test-case-container .issuable-details') do
          page.find('.js-issuable-edit').click
          page.find('.js-vue-markdown-field button.js-zen-enter').click

          expect(page).to have_selector('.zen-backdrop.fullscreen')
        end
      end

      it 'update title and description' do
        title = 'Updated title'
        description = 'Updated test case description.'
        find('.test-case-container .issuable-details .js-issuable-edit').click

        page.within('.test-case-container .issuable-details form') do
          page.find('input#issuable-title').set(title)
          page.find('textarea#issuable-description').set(description)

          click_button 'Save changes'
        end

        wait_for_requests

        page.within('.test-case-container .issuable-details') do
          expect(page.find('.title')).to have_content(title)
          expect(page.find('.description')).to have_content(description)
          expect(page.find('.edited-text')).to have_content("Edited just now by #{user.name}")
        end
      end
    end

    context 'sidebar' do
      it 'shows expand/collapse button' do
        page.within('.test-case-container .right-sidebar') do
          expect(page).to have_button('Collapse sidebar')
        end
      end

      context 'todo' do
        it 'shows todo status' do
          page.within('.test-case-container .issuable-sidebar') do
            expect(page.find('.block.todo')).to have_content('To Do')
            expect(page).to have_button('Add a to do')
          end
        end

        it 'add test case as todo' do
          page.within('.test-case-container .issuable-sidebar') do
            click_button 'Add a to do'

            wait_for_all_requests

            expect(page).to have_button('Mark as done')
          end
        end

        it 'mark test case todo as done' do
          page.within('.test-case-container .issuable-sidebar') do
            click_button 'Add a to do'

            wait_for_all_requests

            click_button 'Mark as done'

            wait_for_all_requests

            expect(page).to have_button('Add a to do')
          end
        end
      end

      context 'labels' do
        it 'shows assigned labels' do
          page.within('.test-case-container .issuable-sidebar') do
            expect(page).to have_selector('.labels-select-wrapper')
            expect(page.find('.labels-select-wrapper .value')).to have_content(label_bug.title)
          end
        end

        it 'shows labels dropdown on edit click' do
          page.within('.test-case-container .issuable-sidebar .labels-select-wrapper') do
            click_button 'Edit'

            wait_for_requests

            expect(page.find('.js-labels-list [data-testid="dropdown-content"]')).to have_selector('li', count: 2)
            expect(page.find('[data-testid="dropdown-footer"]')).to have_selector('li', count: 2)
          end
        end

        it 'applies label using labels dropdown' do
          page.within('.test-case-container .issuable-sidebar .labels-select-wrapper') do
            click_button 'Edit'

            wait_for_requests

            click_button label_doc.title
            page.find('.labels-select-wrapper [data-testid="title"]').click

            wait_for_requests

            expect(page.find('.labels-select-wrapper .value')).to have_content(label_doc.title)
          end
        end
      end
    end
  end

  describe 'for a nonexistent test case' do
    let(:test_case) { non_existing_record_id }

    it 'renders 404 page' do
      requests = inspect_requests do
        visit project_quality_test_case_path(project, test_case)

        wait_for_all_requests
      end

      expect(requests.first.status_code).to eq(404)
    end
  end
end
