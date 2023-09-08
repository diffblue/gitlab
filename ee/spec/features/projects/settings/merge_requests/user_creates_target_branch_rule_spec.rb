# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project settings > Merge Requests > Target branch rules', :js, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }

  before do
    stub_licensed_features(target_branch_rules: true)

    sign_in(project.first_owner)

    visit project_settings_merge_requests_path(project)
  end

  it 'creates a target branch rule' do
    click_button 'Add target branch rule'

    fill_in 'projects_target_branch_rule_name', with: 'dev/*'

    click_button 'No ref selected'

    find('.gl-new-dropdown-item', text: 'spooky-stuff').click

    click_button 'Save'

    wait_for_requests

    expect(page).to have_content('Target branch rule created.')
    expect(page).to have_content('dev/*')
    expect(page).to have_content('spooky-stuff')
  end
end
