# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views iteration', feature_category: :team_planning do
  let_it_be(:now) { Time.zone.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:project_2) { create(:project, group: group) }
  let_it_be(:user) { create(:group_member, :maintainer, user: create(:user), group: group).user }
  let_it_be(:iteration) { create(:iteration, :skip_future_date_validation, iid: 1, id: 2, group: group, title: 'Correct Iteration', start_date: now - 1.day, due_date: now) }
  let_it_be(:other_iteration) { create(:iteration, :skip_future_date_validation, iid: 2, id: 1, group: group, title: 'Wrong Iteration', start_date: now - 4.days, due_date: now - 3.days) }
  let_it_be(:label1) { create(:label, project: project) }
  let_it_be(:issue) { create(:issue, project: project, iteration: iteration, labels: [label1]) }
  let_it_be(:assigned_issue) { create(:issue, project: project, iteration: iteration, assignees: [user], labels: [label1]) }
  let_it_be(:closed_issue) { create(:closed_issue, project: project, iteration: iteration) }
  let_it_be(:other_iteration_issue) { create(:issue, project: project, iteration: other_iteration) }
  let_it_be(:other_project_issue) { create(:issue, project: project_2, iteration: iteration, assignees: [user], labels: [label1]) }

  RSpec.shared_examples 'render iteration page' do
    context 'view an iteration' do
      it 'shows iteration info' do
        aggregate_failures 'shows iteration info and dates' do
          expect(page).to have_content(iteration.title)
          expect(page).to have_content(iteration.description)
          expect(page).to have_content(iteration.start_date.strftime('%b %-d, %Y'))
          expect(page).to have_content(iteration.due_date.strftime('%b %-d, %Y'))
        end

        aggregate_failures 'shows correct summary information' do
          expect(page).to have_content("Completed")
          expect(page).to have_content("Incomplete")
        end

        aggregate_failures 'expect burnup and burndown charts' do
          expect(page).to have_content('Burndown chart')
          expect(page).to have_content('Burnup chart')
        end

        aggregate_failures 'shows only issues that are part of the project' do
          expect(page).to have_content(issue.title)
          expect(page).to have_content(assigned_issue.title)
          expect(page).to have_content(closed_issue.title)
          expect(page).to have_no_content(other_project_issue.title)
          expect(page).to have_no_content(other_iteration_issue.title)
        end

        aggregate_failures 'hides action dropdown for editing the iteration' do
          expect(page).not_to have_button('Actions')
        end
      end
    end
  end

  context 'with license', :js do
    let(:url) { project_iteration_path(project, iteration.id) }

    before do
      stub_licensed_features(iterations: true)
      sign_in(user)

      visit url
      wait_for_requests
    end

    it_behaves_like 'render iteration page'

    context 'when grouping by label' do
      it_behaves_like 'iteration report group by label'
    end
  end

  context 'without license' do
    before do
      stub_licensed_features(iterations: false)
      sign_in(user)
    end

    it 'shows page not found' do
      visit project_iteration_path(project, iteration.id)

      expect(page).to have_title('Not Found')
      expect(page).to have_content('Page Not Found')
    end
  end
end
