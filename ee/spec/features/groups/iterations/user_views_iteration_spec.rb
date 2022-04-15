# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views iteration' do
  let_it_be(:now) { Time.zone.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:sub_group) { create(:group, :private, parent: group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:sub_project) { create(:project, group: sub_group) }
  let_it_be(:user) { create(:group_member, :maintainer, user: create(:user), group: group).user }
  let_it_be(:guest_user) { create(:group_member, :guest, user: create(:user), group: group).user }
  let_it_be(:manual_cadence) { build(:iterations_cadence, group: group, automatic: false).tap { |cadence| cadence.save!(validate: false) } }
  let_it_be(:other_iteration) { create(:iteration, :with_due_date, iterations_cadence: manual_cadence, title: 'Wrong Iteration', start_date: 1.week.ago) }
  let_it_be(:iteration) { create(:iteration, :with_due_date, iterations_cadence: manual_cadence, title: 'Correct Iteration', description: 'iteration description', start_date: Date.today) }
  let_it_be(:sub_group_iteration) { create(:iteration, group: sub_group) }
  let_it_be(:label1) { create(:label, project: project) }
  let_it_be(:issue) { create(:issue, project: project, iteration: iteration, labels: [label1]) }
  let_it_be(:assigned_issue) { create(:issue, project: project, iteration: iteration, assignees: [user], labels: [label1]) }
  let_it_be(:closed_issue) { create(:closed_issue, project: project, iteration: iteration) }
  let_it_be(:sub_group_issue) { create(:issue, project: sub_project, iteration: iteration) }
  let_it_be(:other_iteration_issue) { create(:issue, project: project, iteration: other_iteration) }

  context 'with license', :js do
    before do
      stub_licensed_features(iterations: true)
    end

    shared_examples 'shows iteration info' do
      it 'shows iteration info' do
        aggregate_failures 'expect Iterations highlighted on left sidebar' do
          page.within '.sidebar-top-level-items' do
            expect(page).to have_css('li.active > a', text: 'Iterations')
          end
        end

        aggregate_failures 'expect title, description, and dates' do
          expect(page).to have_content(iteration.title)
          expect(page).to have_content(iteration.description)
          expect(page).to have_content(iteration.period)
        end

        aggregate_failures 'expect summary information' do
          expect(page).to have_content("Completed 25%")
          expect(page).to have_content("Incomplete 25%")
          expect(page).to have_content("Unstarted 50%")
        end

        aggregate_failures 'expect burnup and burndown charts' do
          expect(page).to have_content('Burndown chart')
          expect(page).to have_content('Burnup chart')
        end

        aggregate_failures 'expect list of assigned issues' do
          expect(page).to have_content(issue.title)
          expect(page).to have_content(assigned_issue.title)
          expect(page).to have_content(closed_issue.title)
          expect(page).to have_content(sub_group_issue.title)
          expect(page).not_to have_content(other_iteration_issue.title)
        end

        if shows_actions
          expect(page).to have_button('Actions')
        else
          expect(page).not_to have_button('Actions')
        end
      end
    end

    context 'when user has edit permissions' do
      before do
        stub_feature_flags(iteration_cadences: false)
      end

      it_behaves_like 'shows iteration info' do
        let(:current_user) { user }
        let(:shows_actions) { true }

        before do
          sign_in(current_user)

          visit_iteration(iteration)
        end
      end

      it 'can delete iteration' do
        sign_in(user)

        visit_iteration(iteration)

        click_button 'Actions'
        click_button 'Delete'
        page.within '.gl-modal' do
          click_button 'Delete'
        end

        wait_for_requests

        expect(page).to have_content('No iterations found')
        expect(page).not_to have_content(iteration.title)
      end
    end

    context 'when user does not have edit permissions' do
      it_behaves_like 'shows iteration info' do
        let(:current_user) { guest_user }
        let(:shows_actions) { false }

        before do
          sign_in(current_user)

          visit_iteration(iteration)
        end
      end
    end

    context 'when grouping by label' do
      before do
        stub_feature_flags(iteration_cadences: false)

        sign_in(user)

        visit_iteration(iteration)
      end

      it_behaves_like 'iteration report group by label'
    end

    context 'when iteration_cadences FF is enabled' do
      before do
        stub_feature_flags(iteration_cadences: true)
      end

      context 'when user has edit permissions' do
        let(:current_user) { user }
        let(:shows_actions) { true }

        before do
          sign_in(current_user)

          visit_iteration(iteration, true)
        end

        it 'shows iteration cadence title in the breadcrumb' do
          page.within '[aria-label="Breadcrumbs"]' do
            expect(page).to have_content(manual_cadence.title)
          end
        end

        it_behaves_like 'shows iteration info'

        context 'when iteration cadence is manually scheduled' do
          it 'can delete iteration' do
            click_button 'Actions'
            click_button 'Delete'
            page.within '.gl-modal' do
              click_button 'Delete'
            end

            wait_for_requests

            click_button manual_cadence.title

            expect(page).not_to have_content(iteration.period)
          end
        end

        context 'when iteration cadence is automatically scheduled' do
          let_it_be(:auto_cadence) { create(:iterations_cadence, group: group) }
          let_it_be(:iteration) { create(:iteration, iterations_cadence: auto_cadence, description: 'iteration description', start_date: Date.today) }

          it 'cannot delete iteration' do
            click_button 'Actions'
            expect(page).not_to have_button('Delete')
          end
        end
      end

      context 'when user does not have edit permissions' do
        let(:current_user) { guest_user }
        let(:shows_actions) { false }

        before do
          sign_in(current_user)

          visit_iteration(iteration, true)
        end

        it_behaves_like 'shows iteration info'

        context 'when iteration cadence is manually scheduled' do
          it 'cannot edit iteration' do
            expect(page).not_to have_button('Actions')
          end
        end
      end
    end
  end

  context 'without license' do
    before do
      stub_licensed_features(iterations: false)
      sign_in(user)
    end

    [true, false].each do |iteration_cadences_ff|
      context "when iteration_cadences FF is %{iteration_cadences_ff}" do
        before do
          stub_feature_flags(iteration_cadences: iteration_cadences_ff)
        end

        it 'shows page not found' do
          visit_iteration(iteration, iteration_cadences_ff)

          expect(page).to have_title('Not Found')
          expect(page).to have_content('Page Not Found')
        end
      end
    end
  end

  def visit_iteration(iteration, with_cadence_feature = false)
    if with_cadence_feature
      cadence = iteration.iterations_cadence
      visit group_iteration_cadence_iteration_path(cadence.group, iteration_cadence_id: cadence.id, id: iteration.id)
    else
      visit group_iteration_path(iteration.group, iteration.id)
    end

    wait_for_requests
  end
end
