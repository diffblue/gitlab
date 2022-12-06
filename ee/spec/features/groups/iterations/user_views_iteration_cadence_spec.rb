# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views iteration cadences', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:cadence) { create(:iterations_cadence, group: group) }
  let_it_be(:other_cadence) { create(:iterations_cadence, group: group) }
  let_it_be(:subgroup_cadence) { create(:iterations_cadence, group: subgroup) }
  let_it_be(:iteration_in_cadence) { create(:iteration, iterations_cadence: cadence) }
  let_it_be(:closed_iteration_in_cadence) { create(:iteration, iterations_cadence: cadence, start_date: 2.weeks.ago, due_date: 1.week.ago) }
  let_it_be(:iteration_in_other_cadence) { create(:iteration, iterations_cadence: other_cadence) }

  before do
    stub_licensed_features(iterations: true)
  end

  it 'shows iteration cadences with iterations when expanded', :aggregate_failures do
    visit group_iteration_cadences_path(group)

    expect(page).to have_title('Iteration cadences')
    expect(page).to have_content(cadence.title)
    expect(page).to have_content(other_cadence.title)
    expect(page).not_to have_content(iteration_in_cadence.period)
    expect(page).not_to have_content(iteration_in_other_cadence.period)

    click_button cadence.title

    expect(page).to have_content(iteration_in_cadence.period)
    expect(page).not_to have_content(subgroup_cadence.title)
    expect(page).not_to have_content(iteration_in_other_cadence.period)
    expect(page).not_to have_content(closed_iteration_in_cadence.period)
  end

  it 'only shows completed iterations on Done tab', :aggregate_failures do
    visit group_iteration_cadences_path(group)
    click_link 'Done'
    click_button cadence.title

    expect(page).not_to have_content(iteration_in_cadence.period)
    expect(page).to have_content(closed_iteration_in_cadence.period)
  end

  it 'shows inherited cadences in subgroup', :aggregate_failures do
    visit group_iteration_cadences_path(subgroup)

    expect(page).to have_content(cadence.title)
    expect(page).to have_content(other_cadence.title)
    expect(page).to have_content(subgroup_cadence.title)
  end
end
