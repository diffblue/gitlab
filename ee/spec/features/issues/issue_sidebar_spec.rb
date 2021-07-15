# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Sidebar' do
  include MobileHelpers

  let_it_be(:group) { create(:group, :nested) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:project_without_group) { create(:project, :public) }
  let_it_be(:user) { create(:user)}
  let_it_be(:label) { create(:label, project: project, title: 'bug') }
  let_it_be(:issue) { create(:labeled_issue, project: project, labels: [label]) }
  let_it_be(:issue_no_group) { create(:labeled_issue, project: project_without_group, labels: [label]) }

  before do
    sign_in(user)
  end

  context 'Assignees', :js do
    let(:user2) { create(:user) }
    let(:issue2) { create(:issue, project: project, author: user2) }

    it 'shows label text as "Apply" when assignees are changed' do
      project.add_developer(user)
      visit_issue(project, issue2)

      open_assignees_dropdown
      click_on 'Unassigned'

      expect(page).to have_content('Apply')
    end
  end

  context 'updating weight', :js do
    before do
      project.add_maintainer(user)
      visit_issue(project, issue)
      wait_for_all_requests
    end

    it 'updates weight in sidebar to 0' do
      page.within '.weight' do
        click_button 'Edit'
        send_keys 0, :enter

        expect(page).to have_text '0 - remove weight'
      end
    end

    it 'updates weight in sidebar to no weight by clicking `remove weight`' do
      page.within '.weight' do
        click_button 'Edit'
        send_keys 1, :enter

        expect(page).to have_text '1 - remove weight'

        click_button 'remove weight'

        expect(page).to have_text 'None'
      end
    end

    it 'updates weight in sidebar to no weight by setting an empty value' do
      page.within '.weight' do
        click_button 'Edit'
        send_keys 1, :enter

        expect(page).to have_text '1 - remove weight'

        click_button 'Edit'
        send_keys :backspace, :enter

        expect(page).to have_text 'None'
      end
    end
  end

  context 'as a guest' do
    before do
      project.add_guest(user)
      visit_issue(project, issue)
    end

    it 'does not have a option to edit weight' do
      expect(page).not_to have_selector('.block.weight .js-weight-edit-link')
    end
  end

  context 'as a guest, interacting with collapsed sidebar', :js do
    before do
      project.add_guest(user)
      resize_screen_sm
      visit_issue(project, issue)
    end

    it 'edit weight field does not appear after clicking on weight when sidebar is collapsed then expanding it' do
      find('.js-weight-collapsed-block').click
      # Expand sidebar
      open_issue_sidebar
      expect(page).not_to have_selector('.block.weight .form-control')
    end
  end

  context 'health status', :js do
    before do
      project.add_developer(user)
    end

    context 'when health status feature is available' do
      before do
        stub_licensed_features(issuable_health_status: true)

        visit_issue(project, issue)
      end

      it 'shows health status on sidebar' do
        expect(page).to have_selector('.block.health-status')
      end

      context 'when user closes an issue' do
        it 'disables the edit button' do
          page.within('.detail-page-header') do
            click_button 'Close issue'
          end

          page.within('.health-status') do
            expect(page).to have_button('Edit', disabled: true)
          end
        end
      end
    end

    context 'when health status feature is not available' do
      it 'does not show health status on sidebar' do
        stub_licensed_features(issuable_health_status: false)

        visit_issue(project, issue)

        expect(page).not_to have_selector('.block.health-status')
      end
    end
  end

  context 'Iterations', :js do
    context 'when iterations feature available' do
      let_it_be(:iteration_cadence) { create(:iterations_cadence, group: group, active: true) }
      let_it_be(:iteration) { create(:iteration, iterations_cadence: iteration_cadence, group: group, start_date: 1.day.from_now, due_date: 2.days.from_now) }
      let_it_be(:iteration2) { create(:iteration, iterations_cadence: iteration_cadence, group: group, start_date: 2.days.ago, due_date: 1.day.ago, state: 'closed', skip_future_date_validation: true) }

      before do
        stub_licensed_features(iterations: true)

        project.add_developer(user)
      end

      context 'when `iteration_cadences` feature flag is off' do
        before do
          stub_feature_flags(iteration_cadences: false)

          visit_issue(project, issue)

          wait_for_all_requests
        end

        it 'selects and updates the right iteration', :aggregate_failures do
          find_and_click_edit_iteration

          within '[data-testid="iteration-edit"]' do
            expect(page).not_to have_text(iteration_cadence.title)
            expect(page).to have_text(iteration.title)
          end

          select_iteration(iteration.title)

          within '[data-testid="select-iteration"]' do
            expect(page).not_to have_text(iteration_cadence.title)
            expect(page).to have_text(iteration.title)
          end

          find_and_click_edit_iteration

          select_iteration('No iteration')

          expect(page.find('[data-testid="select-iteration"]')).to have_content('None')
        end

        it 'does not show closed iterations' do
          find_and_click_edit_iteration

          page.within '[data-testid="iteration-edit"]' do
            expect(page).not_to have_content iteration2.title
          end
        end
      end

      context 'when `iteration_cadences` feature flag is on' do
        before do
          stub_feature_flags(iteration_cadences: true)

          visit_issue(project, issue)

          wait_for_all_requests
        end

        it 'selects and updates the right iteration', :aggregate_failures do
          find_and_click_edit_iteration

          within '[data-testid="iteration-edit"]' do
            expect(page).to have_text(iteration_cadence.title)
            expect(page).to have_text(iteration.title)
          end

          select_iteration(iteration.title)

          within '[data-testid="select-iteration"]' do
            expect(page).to have_text(iteration_cadence.title)
            expect(page).to have_text(iteration.title)
          end

          find_and_click_edit_iteration

          select_iteration('No iteration')

          expect(page.find('[data-testid="select-iteration"]')).to have_content('None')
        end

        it 'does not show closed iterations' do
          find_and_click_edit_iteration

          page.within '[data-testid="iteration-edit"]' do
            expect(page).not_to have_content iteration2.title
          end
        end
      end
    end

    context 'when a project does not have a group' do
      before do
        stub_licensed_features(iterations: true)

        project_without_group.add_developer(user)

        visit_issue(project_without_group, issue_no_group)

        wait_for_all_requests
      end

      it 'cannot find the select-iteration edit button' do
        expect(page).not_to have_selector('[data-testid="select-iteration"]')
      end
    end

    context 'when iteration feature is not available' do
      before do
        stub_licensed_features(iterations: false)

        project.add_developer(user)

        visit_issue(project, issue)

        wait_for_all_requests
      end

      it 'cannot find the select-iteration edit button' do
        expect(page).not_to have_selector('[data-testid="select-iteration"]')
      end
    end
  end

  def find_and_click_edit_iteration
    page.find('[data-testid="iteration-edit"] [data-testid="edit-button"]').click

    wait_for_all_requests
  end

  def select_iteration(iteration_name)
    click_button(iteration_name)

    wait_for_all_requests
  end

  def visit_issue(project, issue)
    visit project_issue_path(project, issue)
  end

  def open_issue_sidebar
    find('aside.right-sidebar.right-sidebar-collapsed .js-sidebar-toggle').click
    find('aside.right-sidebar.right-sidebar-expanded')
  end

  def open_assignees_dropdown
    page.within('.assignee') do
      click_button('Edit')
      wait_for_requests
    end
  end
end
