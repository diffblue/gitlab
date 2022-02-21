# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Iterations list', :js do
  let_it_be(:now) { Time.zone.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:current_iteration) { create(:iteration, :skip_future_date_validation, group: group, start_date: now - 1.day, due_date: now, title: 'Started iteration') }
  let_it_be(:upcoming_iteration) { create(:iteration, group: group, start_date: now + 1.day, due_date: now + 2.days) }
  let_it_be(:closed_iteration) { create(:closed_iteration, :skip_future_date_validation, group: group, start_date: now - 3.days, due_date: now - 2.days) }
  let_it_be(:subgroup_iteration) { create(:iteration, :skip_future_date_validation, group: subgroup, start_date: now - 3.days, due_date: now + 4.days) }
  let_it_be(:subgroup_closed_iteration) { create(:iteration, :skip_future_date_validation, group: subgroup, start_date: now - 5.days, due_date: now - 4.days) }

  context 'as guest' do
    context 'when in group' do
      before do
        visit group_iterations_path(group)
      end

      it 'hides New iteration button' do
        expect(page).not_to have_link('New iteration', href: new_group_iteration_path(group))
      end

      it 'shows iterations on each tab' do
        aggregate_failures do
          expect(page).to have_link(current_iteration.title)
          expect(page).to have_link(upcoming_iteration.title)
          expect(page).not_to have_link(closed_iteration.title)
          expect(page).not_to have_link(subgroup_iteration.title)
          expect(page).not_to have_link(subgroup_closed_iteration.title)
        end

        click_link('Closed')

        aggregate_failures do
          expect(page).to have_link(closed_iteration.title)
          expect(page).not_to have_link(current_iteration.title)
          expect(page).not_to have_link(upcoming_iteration.title)
          expect(page).not_to have_link(subgroup_iteration.title)
          expect(page).not_to have_link(subgroup_closed_iteration.title)
        end

        click_link('All')

        aggregate_failures do
          expect(page).to have_link(current_iteration.title)
          expect(page).to have_link(upcoming_iteration.title)
          expect(page).to have_link(closed_iteration.title)
          expect(page).not_to have_link(subgroup_iteration.title)
          expect(page).not_to have_link(subgroup_closed_iteration.title)
        end
      end

      context 'when an iteration is clicked' do
        it 'redirects to an iteration report within the group context' do
          click_link('Started iteration')

          wait_for_requests

          expect(page).to have_current_path(group_iteration_path(group, current_iteration.id))
        end
      end
    end

    context 'when in subgroup' do
      before do
        visit group_iterations_path(subgroup)
      end

      it 'shows iterations on each tab including ancestor iterations' do
        aggregate_failures do
          expect(page).to have_link(current_iteration.title)
          expect(page).to have_link(upcoming_iteration.title)
          expect(page).not_to have_link(closed_iteration.title)
          expect(page).to have_link(subgroup_iteration.title)
          expect(page).not_to have_link(subgroup_closed_iteration.title)
        end

        click_link('Closed')

        aggregate_failures do
          expect(page).to have_link(closed_iteration.title)
          expect(page).to have_link(subgroup_closed_iteration.title)
          expect(page).not_to have_link(current_iteration.title)
          expect(page).not_to have_link(upcoming_iteration.title)
          expect(page).not_to have_link(subgroup_iteration.title)
        end

        click_link('All')

        aggregate_failures do
          expect(page).to have_link(current_iteration.title)
          expect(page).to have_link(upcoming_iteration.title)
          expect(page).to have_link(closed_iteration.title)
          expect(page).to have_link(subgroup_iteration.title)
          expect(page).to have_link(subgroup_closed_iteration.title)
        end
      end
    end
  end

  context 'as user' do
    before do
      stub_licensed_features(iterations: true)
      group.add_developer(user)
      sign_in(user)
      visit group_iterations_path(group)
    end

    it 'shows "New iteration" button' do
      expect(page).to have_link('New iteration', href: new_group_iteration_path(group))
    end
  end
end
