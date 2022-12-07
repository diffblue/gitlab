# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User edits iteration', feature_category: :team_planning do
  let_it_be(:now) { Time.zone.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:group_member, :maintainer, user: create(:user), group: group).user }
  let_it_be(:guest_user) { create(:group_member, :guest, user: create(:user), group: group).user }
  let_it_be(:cadence) { create(:iterations_cadence, group: group) }
  let_it_be(:iteration) { create(:iteration, :skip_future_date_validation, description: 'Iteration description', start_date: now - 1.day, due_date: now, iterations_cadence: cadence) }
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

      shared_examples 'manually managed iteration' do
        let_it_be(:manual_cadence) { build(:iterations_cadence, group: group, automatic: false).tap { |cadence| cadence.save!(validate: false) } }
        let_it_be(:iteration) { create(:iteration, :skip_future_date_validation, title: 'Correct Iteration', description: 'Iteration description', start_date: now - 1.day, due_date: now, iterations_cadence: manual_cadence) }

        context 'load edit page directly', :js do
          before do
            visit edit_iteration_page

            wait_for_requests
          end

          it 'prefills fields and allows updating all values' do
            aggregate_failures do
              expect(find_field('Title').value).to eq(iteration.title)
              expect(find_field('Description').value).to eq(iteration.description)
              expect(start_date_field.value).to have_content(iteration.start_date)
              expect(due_date_field.value).to have_content(iteration.due_date)
            end

            updated_title = 'Updated iteration title'
            updated_desc = 'Updated iteration desc'

            fill_in('Title', with: updated_title)
            fill_in('Description', with: updated_desc)
            start_date_input
            due_date_input

            click_button('Save changes')

            aggregate_failures do
              expect(page).to have_content(updated_title)
              expect(page).to have_content(updated_desc)
              expect(page).to have_content(new_start_date.strftime('%b %-d, %Y'))
              expect(page).to have_content(new_due_date.strftime('%b %-d, %Y'))
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
              expect(find_field('Title').value).to eq(iteration.title)
              expect(find_field('Description').value).to eq(iteration.description)
              expect(start_date_field.value).to have_content(iteration.start_date)
              expect(due_date_field.value).to have_content(iteration.due_date)
              expect(page).to have_current_path(edit_iteration_page)
            end
          end
        end
      end

      context 'using manual iteration cadences' do
        let(:iteration_page) { group_iteration_cadence_iteration_path(group, iteration_cadence_id: manual_cadence.id, id: iteration.id) }
        let(:edit_iteration_page) { edit_group_iteration_cadence_iteration_path(group, iteration_cadence_id: manual_cadence.id, id: iteration.id) }
        let(:start_date_field) { find_field('Start date') }
        let(:due_date_field) { find_field('Due date') }

        let(:start_date_input) do
          fill_in 'Start date', with: new_start_date
          start_date_field.native.send_keys :enter
        end

        let(:due_date_input) do
          fill_in 'Due date', with: new_due_date
          due_date_field.native.send_keys :enter
        end

        it_behaves_like 'manually managed iteration'
      end

      context 'using automatic iteration cadences' do
        let(:iteration_page) { group_iteration_cadence_iteration_path(group, iteration_cadence_id: cadence.id, id: iteration.id) }
        let(:edit_iteration_page) { edit_group_iteration_cadence_iteration_path(group, iteration_cadence_id: cadence.id, id: iteration.id) }

        context 'load edit page directly', :js do
          before do
            visit edit_iteration_page

            wait_for_requests
          end

          it 'prefills and allows updating description', :aggregate_failures do
            expect(find_field("Description").value).to eq(iteration.description)

            updated_desc = 'Updated iteration desc'

            fill_in('Description', with: updated_desc)
            click_button('Save changes')

            expect(page).to have_content(updated_desc)
          end
        end

        context 'load edit page from report', :js do
          before do
            visit iteration_page
          end

          it 'prefills description and updates URL' do
            find(dropdown_selector).click
            click_link_or_button('Edit')

            expect(find_field("Description").value).to eq(iteration.description)
            expect(page).to have_current_path(edit_iteration_page)
          end
        end
      end
    end

    context 'as guest user', :js do
      before do
        sign_in(guest_user)
      end

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
  end
end
