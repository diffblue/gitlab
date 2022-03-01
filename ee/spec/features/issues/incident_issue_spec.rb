# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Incident Detail', :js do
  let_it_be(:project) { create(:project, :public) }

  let_it_be(:user) { create(:user) }
  let_it_be(:started_at) { Time.now.rfc3339 }
  let_it_be(:incident) { create(:incident, project: project, description: 'hello') }

  context 'when user displays the incident' do
    before do
      stub_licensed_features(incident_timeline_events: true)
      stub_feature_flags(incident_timeline_event_tab: true)
      project.add_developer(user)
      sign_in(user)
    end

    context 'when on timeline events tab from incident route' do
      before do
        visit project_issues_incident_path(project, incident)
        wait_for_requests
        click_link 'Timeline'
      end

      it 'does not show the linked issues and notes/comment components' do
        page.within('.issuable-details') do
          hidden_items = find_all('.js-issue-widgets')

          # Linked Issues/MRs and comment box are hidden on page
          expect(hidden_items.count).to eq(0)
        end
      end
    end

    context 'when on timeline events tab from issue route' do
      before do
        visit project_issue_path(project, incident)
        wait_for_requests
        click_link 'Timeline'
      end

      it 'does not show the linked issues and notes/comment commponents' do
        page.within('.issuable-details') do
          hidden_items = find_all('.js-issue-widgets')

          # Linked Issues/MRs and comment box are hidden on page
          expect(hidden_items.count).to eq(0)
        end
      end
    end
  end
end
