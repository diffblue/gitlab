# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Jira issues list', feature_category: :integrations do
  let_it_be(:project, refind: true) { create(:project) }
  let_it_be(:jira_integration) { create(:jira_integration, project: project, issues_enabled: true, project_key: 'GL') }

  let(:user) { create(:user) }

  before do
    stub_licensed_features(jira_issues_integration: true)
    project.add_member(user, :developer)
    sign_in(user)
    stub_request(:get, /.*jira.example.com.*/)
  end

  context 'when jira_issues_integration licensed feature is not available' do
    before do
      stub_licensed_features(jira_issues_integration: false)
    end

    it 'does not render "Create new issue" button' do
      visit project_integrations_jira_issues_path(project)

      expect(page).to have_gitlab_http_status(:not_found)
      expect(page).not_to have_link('Create new issue in Jira')
    end
  end

  it 'renders "Create new issue" button', :js do
    visit project_integrations_jira_issues_path(project)

    expect(page).to have_link('Create new issue in Jira', href: "#{jira_integration.url}/secure/CreateIssue!default.jspa")
  end

  context 'on gitlab.com' do
    before do
      allow(Gitlab).to receive(:com?).and_return(true)
    end

    it 'includes the Atlassian referrer in Jira links', :js do
      visit project_integrations_jira_issues_path(project)

      referrer = Integrations::Jira::ATLASSIAN_REFERRER_GITLAB_COM.to_query

      expect(page).to have_link('Open Jira', href: "#{jira_integration.url}?#{referrer}")
      expect(page).to have_link('Create new issue in Jira', href: "#{jira_integration.url}/secure/CreateIssue!default.jspa?#{referrer}"), count: 2
    end
  end
end
