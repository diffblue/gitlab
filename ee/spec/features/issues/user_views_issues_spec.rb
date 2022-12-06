# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views issues page', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue1) { create(:issue, project: project, health_status: 'on_track', weight: 2) }
  let_it_be(:issue2) { create(:issue, project: project, health_status: 'needs_attention') }
  let_it_be(:issue3) { create(:issue, project: project, health_status: 'at_risk') }

  before do
    stub_licensed_features(blocked_issues: true, issuable_health_status: true, issue_weights: true)
    sign_in(user)
    visit project_issues_path(project)
  end

  before_all do
    create(:issue_link, source: issue1, target: issue2, link_type: IssueLink::TYPE_BLOCKS)
  end

  describe 'issue card' do
    it 'shows health status, blocking issues, and weight information', :aggregate_failures do
      within '.issue:nth-of-type(1)' do
        expect(page).to have_css '.badge-danger', text: 'At risk'
        expect(page).not_to have_css '[data-testid="blocking-issues"]'
        expect(page).not_to have_css '.issuable-weight'
      end

      within '.issue:nth-of-type(2)' do
        expect(page).to have_css '.badge-warning', text: 'Needs attention'
        expect(page).not_to have_css '[data-testid="blocking-issues"]'
        expect(page).not_to have_css '.issuable-weight'
      end

      within '.issue:nth-of-type(3)' do
        expect(page).to have_css '.badge-success', text: 'On track'
        expect(page).to have_css '[data-testid="blocking-issues"]', text: 1
        expect(page).to have_css '.issuable-weight', text: 2
      end
    end
  end
end
