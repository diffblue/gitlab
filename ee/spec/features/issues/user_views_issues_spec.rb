# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User views issues page', :js do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue1) { create(:issue, project: project, health_status: 'on_track', weight: 2) }
  let_it_be(:issue2) { create(:issue, project: project, health_status: 'needs_attention') }
  let_it_be(:issue3) { create(:issue, project: project, health_status: 'at_risk') }

  before do
    sign_in(user)
    visit project_issues_path(project)
  end

  before_all do
    create(:issue_link, source: issue1, target: issue2, link_type: IssueLink::TYPE_BLOCKS)
  end

  describe 'issue card' do
    it 'shows health status, blocking issues, and weight information', :aggregate_failures do
      within '.issue:nth-of-type(1)' do
        expect(page).to have_css '.status-at-risk', text: 'At risk'
        expect(page).not_to have_css '.blocking-issues'
        expect(page).not_to have_css '.issuable-weight'
      end

      within '.issue:nth-of-type(2)' do
        expect(page).to have_css '.status-needs-attention', text: 'Needs attention'
        expect(page).not_to have_css '.blocking-issues'
        expect(page).not_to have_css '.issuable-weight'
      end

      within '.issue:nth-of-type(3)' do
        expect(page).to have_css '.status-on-track', text: 'On track'
        expect(page).to have_css '.blocking-issues', text: 1
        expect(page).to have_css '.issuable-weight', text: 2
      end
    end
  end
end
