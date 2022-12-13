# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupMilestones, feature_category: :team_planning do
  let(:user) { create(:user) }
  let(:group) { create(:group, :private) }
  let(:project) { create(:project, namespace: group) }
  let!(:group_member) { create(:group_member, group: group, user: user) }
  let!(:closed_milestone) { create(:closed_milestone, group: group, title: 'version1', description: 'closed milestone') }
  let!(:milestone) { create(:milestone, group: group, title: 'version2', description: 'open milestone', start_date: Date.today, due_date: Date.today + 3.days) }
  let!(:issue1) { create(:issue, created_at: Date.today.beginning_of_day, weight: 2, project: project, milestone: milestone) }
  let!(:issue2) { create(:issue, created_at: Date.today.middle_of_day, weight: 5, project: project, milestone: milestone) }
  let(:issues_route) { "/groups/#{group.id}/milestones/#{milestone.id}/issues" }

  before do
    project.add_developer(user)
  end

  it 'matches V4 EE-specific  response schema for a list of issues' do
    get api(issues_route, user)

    expect(response).to have_gitlab_http_status(:ok)
    expect(response).to match_response_schema('public_api/v4/issues', dir: 'ee')
  end

  it_behaves_like 'group and project milestone burndowns', '/groups/:id/milestones/:milestone_id/burndown_events' do
    let(:route) { "/groups/#{group.id}/milestones" }
  end
end
