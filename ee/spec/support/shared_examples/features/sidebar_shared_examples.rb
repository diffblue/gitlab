# frozen_string_literal: true

RSpec.shared_examples 'issue boards sidebar EE' do
  context 'epics' do
    let(:epic_widget) { find('[data-testid="sidebar-epic"]') }

    context 'when epic feature available' do
      let_it_be(:epic1) { create(:epic, group: group) }
      let_it_be(:epic2) { create(:epic, group: group) }

      let_it_be(:epic_issue, reload: true) { create(:epic_issue, epic: epic1, issue: issue) }

      context 'when the issue is associated with an epic' do
        before do
          stub_licensed_features(epics: true)

          first_card_with_epic.click
          wait_for_requests
        end

        it 'displays name of epic and links to it' do
          within(epic_widget) do
            expect(page).to have_link(epic1.title)
            expect(find_link(epic1.title)[:href]).to end_with(epic_path(epic1))
          end
        end

        it 'updates the epic associated with the issue' do
          within(epic_widget) do
            click_button 'Edit'
            wait_for_requests

            find('.gl-dropdown-item', text: epic2.title).click
            wait_for_requests

            expect(page).to have_content(epic2.title)
          end
        end

        context 'when epics feature is not available' do
          before do
            stub_licensed_features(epics: false)

            first_card_with_epic.click

            wait_for_all_requests
          end

          it 'cannot find sidebar-epic' do
            expect(page).not_to have_selector('[data-testid="sidebar-epic"]')
          end
        end
      end
    end

    context 'iterations' do
      context 'when iterations feature available' do
        let_it_be(:cadence) { create(:iterations_cadence, group: group) }
        let_it_be(:iteration) { create(:iteration, iterations_cadence: cadence, start_date: 1.day.from_now, due_date: 2.days.from_now, title: 'Iteration 1') }
        let_it_be(:iteration2) { create(:iteration, iterations_cadence: cadence, start_date: 2.days.ago, due_date: 1.day.ago, title: 'Iteration 2', state: 'closed', skip_future_date_validation: true) }

        before do
          iteration
          stub_licensed_features(iterations: true)

          first_card.click

          wait_for_all_requests
        end

        it 'selects and updates the right iteration' do
          find_and_click_edit_iteration

          select_iteration(iteration.title)

          expect(page.find('[data-testid="iteration-edit"]')).to have_content('Iteration 1')

          find_and_click_edit_iteration

          select_iteration('No iteration')

          expect(page.find('[data-testid="iteration-edit"]')).to have_content('None')
        end

        context 'when iteration feature is not available' do
          before do
            stub_licensed_features(iterations: false)

            first_card.click

            wait_for_all_requests
          end

          it 'cannot find the iteration-edit' do
            expect(page).not_to have_selector('[data-testid="iteration-edit"]')
          end
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
  end

  context 'weight' do
    context 'when issue weight feature available' do
      before do
        stub_licensed_features(issue_weights: true)

        first_card.click

        wait_for_all_requests
      end

      it 'selects and updates weight' do
        page.within('[data-testid="sidebar-weight"]') do
          expect(page).to have_content('None')

          click_button('Edit')

          fill_in 'Enter a number', with: '2'
          find_field('Enter a number').native.send_keys :enter

          wait_for_all_requests

          expect(page).to have_content('2')
        end
      end

      context 'when issue weight feature is not available' do
        before do
          stub_licensed_features(issue_weights: false)

          first_card.click

          wait_for_all_requests
        end

        it 'cannot find the sidebar-weight' do
          expect(page).not_to have_selector('[data-testid="sidebar-weight"]')
        end
      end
    end
  end
end
