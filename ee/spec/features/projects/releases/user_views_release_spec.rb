# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views Release', :js, feature_category: :release_orchestration do
  it 'renders the group milestone' do
    stub_licensed_features(group_milestone_project_releases: true)

    group = create(:group)
    project = create(:project, :repository, group: group)
    group_milestone = create(:milestone, group: group, title: 'group_milestone_1')
    release = create(:release, project: project, milestones: [group_milestone])

    user = create(:user, developer_projects: [project])
    sign_in(user)
    visit project_release_path(project, release)

    expect(page).to have_content("group_milestone_1")
  end
end
