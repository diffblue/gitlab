# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Iterations list', :js do
  let_it_be(:now) { Time.zone.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:user) { create(:user) }

  let_it_be(:current_iteration) { create(:iteration, :skip_future_date_validation, group: group, start_date: now - 1.day, due_date: now) }
  let_it_be(:upcoming_iteration) { create(:iteration, group: group, start_date: now + 1.day, due_date: now + 2.days) }
  let_it_be(:closed_iteration) { create(:closed_iteration, :skip_future_date_validation, group: group, start_date: now - 3.days, due_date: now - 2.days) }

  context 'as guest' do
    before do
      visit project_iterations_path(project)
    end

    it 'shows iterations on each tab', :aggregate_failures do
      expect(page).to have_link(current_iteration.title, href: project_iteration_path(project, current_iteration.id))
      expect(page).to have_link(upcoming_iteration.title, href: project_iteration_path(project, upcoming_iteration.id))
      expect(page).not_to have_link(closed_iteration.title)

      click_link('Closed')

      expect(page).to have_link(closed_iteration.title, href: project_iteration_path(project, closed_iteration.id))
      expect(page).not_to have_link(current_iteration.title)
      expect(page).not_to have_link(upcoming_iteration.title)

      click_link('All')

      expect(page).to have_link(current_iteration.title, href: project_iteration_path(project, current_iteration.id))
      expect(page).to have_link(upcoming_iteration.title, href: project_iteration_path(project, upcoming_iteration.id))
      expect(page).to have_link(closed_iteration.title, href: project_iteration_path(project, closed_iteration.id))
    end
  end

  context 'as authorized user' do
    before do
      project.add_developer(user)
      sign_in(user)
      visit project_iterations_path(project)
    end

    it 'does not show "New iteration" button' do
      expect(page).not_to have_link('New iteration')
    end
  end
end
