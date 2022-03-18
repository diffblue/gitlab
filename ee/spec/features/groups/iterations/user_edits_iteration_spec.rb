# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edits iteration' do
  let_it_be(:now) { Time.zone.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:group_member, :maintainer, user: create(:user), group: group ).user }
  let_it_be(:guest_user) { create(:group_member, :guest, user: create(:user), group: group ).user }
  let_it_be(:cadence) { create(:iterations_cadence, group: group) }
  let_it_be(:iteration) { create(:iteration, :skip_future_date_validation, group: group, title: 'Correct Iteration', description: 'Iteration description', start_date: now - 1.day, due_date: now, iterations_cadence: cadence) }
  let_it_be(:new_start_date) { now + 4.days }
  let_it_be(:new_due_date) { now + 5.days }

  dropdown_selector = '[data-testid="actions-dropdown"]'

  context 'with license' do
    using RSpec::Parameterized::TableSyntax

    before do
      stub_licensed_features(iterations: true)
    end

    context 'as authorized user' do
      before do
        sign_in(user)
      end

      let(:start_date_with_cadences_input) do
        page.find('#iteration-start-date')
      end

      let(:due_date_with_cadences_input) do
        page.find('#iteration-due-date')
      end

      let(:start_date_without_cadences_input) do
        input = page.first('[data-testid="gl-datepicker-input"]')
        input.set(now - 1.day)
        input
      end

      let(:due_date_without_cadences_input) do
        input = all('[data-testid="gl-datepicker-input"]').last
        input.set(now)
        input
      end

      let(:updated_start_date_with_cadences) do
        fill_in('Start date', with: new_start_date.strftime('%Y-%m-%d'))
        new_start_date.strftime('%b %-d, %Y')
      end

      let(:updated_due_date_with_cadences) do
        fill_in('Due date', with: new_due_date.strftime('%Y-%m-%d'))
        new_due_date.strftime('%b %-d, %Y')
      end

      let(:updated_start_date_without_cadences) do
        start_date_without_cadences_input.set(new_start_date)
        new_start_date.strftime('%b %-d, %Y')
      end

      let(:updated_due_date_without_cadences) do
        # TODO: Reported issue with Capybara
        # Use fill_in instead, update datepicker to have labels
        due_date_without_cadences_input.set('')

        due_date_without_cadences_input.set(new_due_date)
        new_due_date.strftime('%b %-d, %Y')
      end

      let(:iteration_with_cadences_page) { group_iteration_cadence_iteration_path(group, iteration_cadence_id: cadence.id, id: iteration.id) }
      let(:iteration_without_cadences_page) { group_iteration_path(iteration.group, iteration.id) }

      let(:edit_iteration_with_cadences_page) { edit_group_iteration_cadence_iteration_path(group, iteration_cadence_id: cadence.id, id: iteration.id) }
      let(:edit_iteration_without_cadences_page) { edit_group_iteration_path(iteration.group, iteration.id) }

      where(:using_cadences, :start_date_input, :due_date_input, :updated_start_date, :updated_due_date, :iteration_page, :edit_iteration_page) do
        true  | ref(:start_date_with_cadences_input)    | ref(:due_date_with_cadences_input)    | ref(:updated_start_date_with_cadences)    | ref(:updated_due_date_with_cadences)    | ref(:iteration_with_cadences_page)    | ref(:edit_iteration_with_cadences_page)
        false | ref(:start_date_without_cadences_input) | ref(:due_date_without_cadences_input) | ref(:updated_start_date_without_cadences) | ref(:updated_due_date_without_cadences) | ref(:iteration_without_cadences_page) | ref(:edit_iteration_without_cadences_page)
      end

      with_them do
        context 'load edit page directly', :js do
          before do
            visit edit_iteration_page

            wait_for_requests
          end

          it 'prefills fields and allows updating all values' do
            aggregate_failures do
              expect(title_input.value).to eq(iteration.title)
              expect(description_input.value).to eq(iteration.description)
              expect(start_date_input.value).to have_content(iteration.start_date)
              expect(due_date_input.value).to have_content(iteration.due_date)
            end

            updated_title = 'Updated iteration title'
            updated_desc = 'Updated iteration desc'

            fill_in('Title', with: updated_title)
            fill_in('Description', with: updated_desc)
            start_date = updated_start_date
            due_date = updated_due_date

            click_button('Update iteration')

            aggregate_failures do
              expect(page).to have_content(updated_title)
              expect(page).to have_content(updated_desc)
              expect(page).to have_content(start_date)
              expect(page).to have_content(due_date)
              expect(page).to have_current_path(iteration_page)
            end
          end
        end

        context 'load edit page from report', :js do
          before do
            visit iteration_page
          end

          it 'prefills fields and updates URL' do
            find(dropdown_selector).click
            click_link_or_button('Edit')

            aggregate_failures do
              expect(title_input.value).to eq(iteration.title)
              expect(description_input.value).to eq(iteration.description)
              expect(start_date_input.value).to have_content(iteration.start_date)
              expect(due_date_input.value).to have_content(iteration.due_date)
              expect(page).to have_current_path(edit_iteration_page)
            end
          end
        end
      end
    end

    context 'as guest user' do
      before do
        sign_in(guest_user)
      end

      context 'with cadences', :js do
        it 'does not show edit dropdown' do
          visit group_iteration_cadence_iteration_path(iteration.group, iteration_cadence_id: cadence.id, id: iteration.id)

          expect(page).to have_content(iteration.title)
          expect(page).not_to have_selector(dropdown_selector)
        end

        it 'redirects to cadence list page when loading edit page directly' do
          visit edit_group_iteration_cadence_iteration_path(iteration.group, iteration_cadence_id: cadence.id, id: iteration.id)

          expect(page).to have_content(cadence.title)
          expect(page).to have_current_path("#{group_iteration_cadences_path(group)}/")
        end
      end

      context 'without cadences' do
        it 'does not show edit dropdown', :js do
          visit group_iteration_path(iteration.group, iteration.id)

          expect(page).to have_content(iteration.title)
          expect(page).not_to have_selector(dropdown_selector)
        end

        it '404s when loading edit page directly' do
          visit edit_group_iteration_path(iteration.group, iteration.id)

          expect(page).to have_gitlab_http_status(:not_found)
        end
      end
    end

    def title_input
      page.find('#iteration-title')
    end

    def description_input
      page.find('#iteration-description')
    end
  end
end
