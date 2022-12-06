# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User creates iteration in a cadence', :js, feature_category: :team_planning do
  let_it_be(:now) { Time.zone.now }
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:group_member, :maintainer, user: create(:user), group: group).user }
  let_it_be(:cadence) { build(:iterations_cadence, group: group, automatic: false, duration_in_weeks: 0).tap { |cadence| cadence.save!(validate: false) } }

  before do
    stub_licensed_features(iterations: true)
    sign_in(user)

    visit new_group_iteration_cadence_iteration_path(group, iteration_cadence_id: cadence.id)
  end

  it 'prefills fields and allows updating all values' do
    title = 'Iteration title'
    desc = 'Iteration desc'
    start_date = now + 4.days
    due_date = now + 5.days

    fill_in('Title', with: title)
    fill_in('Description', with: desc)
    fill_in('Start date', with: start_date.strftime('%Y-%m-%d'))
    fill_in('Due date', with: due_date.strftime('%Y-%m-%d'))
    click_button('Create iteration')

    wait_for_requests

    iteration = Iteration.last

    aggregate_failures do
      expect(page).to have_content(title)
      expect(page).to have_content(desc)
      expect(page).to have_content(start_date.strftime('%b %-d, %Y'))
      expect(page).to have_content(due_date.strftime('%b %-d, %Y'))
      expect(page).to have_current_path(group_iteration_cadence_iteration_path(group, iteration_cadence_id: cadence.id, id: iteration.id))
    end
  end
end
