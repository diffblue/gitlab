# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::ProjectMilestones, feature_category: :team_planning do
  let(:user) { create(:user) }
  let!(:project) { create(:project, namespace: user.namespace ) }
  let!(:milestone) { create(:milestone, project: project, title: 'version2', description: 'open milestone', start_date: Date.today, due_date: Date.today + 3.days) }
  let!(:issue1) { create(:issue, created_at: Date.today.beginning_of_day, weight: 2, project: project, milestone: milestone) }
  let!(:issue2) { create(:issue, created_at: Date.today.middle_of_day, weight: 5, project: project, milestone: milestone) }
  let(:issues_route) { "/projects/#{project.id}/milestones/#{milestone.id}/issues" }

  before do
    project.add_developer(user)
  end

  it 'matches V4 EE-specific response schema for a list of issues' do
    get api(issues_route, user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(response).to match_response_schema('public_api/v4/issues', dir: 'ee')
  end

  it_behaves_like 'group and project milestone burndowns', '/projects/:id/milestones/:milestone_id/burndown_events' do
    let(:route) { "/projects/#{project.id}/milestones" }
  end
end
