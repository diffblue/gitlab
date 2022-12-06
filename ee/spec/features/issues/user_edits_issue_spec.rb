# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Issues > User edits issue", :js, feature_category: :team_planning do
  let!(:project)   { create(:project) }
  let!(:user)      { create(:user) }
  let!(:milestone) { create(:milestone, project: project) }
  let!(:label)     { create(:label, project: project) }
  let!(:issue)     { create(:issue, project: project, assignees: [user], milestone: milestone) }

  context 'with multiple_issue_assignees' do
    it 'displays plural Assignees title' do
      stub_licensed_features(multiple_issue_assignees: true)
      project.add_maintainer(user)
      sign_in(user)
      visit edit_project_issue_path(project, issue)
      expect(page).to have_content "Assignees"
    end
  end
end
