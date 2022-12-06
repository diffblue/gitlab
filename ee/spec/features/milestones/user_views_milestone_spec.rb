# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "User views milestone", feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:no_access_project) { create(:project, :repository, group: group) }
  let_it_be(:milestone) { create(:milestone, group: group) }

  before do
    stub_licensed_features(group_milestone_project_releases: true)

    project.add_developer(user)
    sign_in(user)
  end

  it 'only shows releases that user has access to' do
    create(:release, name: 'PUBLIC RELEASE', project: project, milestones: [milestone])
    create(:release, name: 'PRIVATE RELEASE', project: no_access_project, milestones: [milestone])

    visit(group_milestones_path(group))

    expect(page.find('.milestone')).to have_text('PUBLIC RELEASE')
    expect(page.find('.milestone')).not_to have_text('PRIVATE RELEASE')
    expect(page.find('.milestone')).to have_text('1 more release')
  end
end
