# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.vulnerabilities.externalIssueLinks', feature_category: :vulnerability_management do
  include GraphqlHelpers
  include ReactiveCachingHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:jira_integration) { create(:jira_integration, project: project, issues_enabled: true, project_key: 'GV') }
  let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }
  let_it_be(:vulnerability) { create(:vulnerability, :with_finding, project: project) }
  let_it_be(:vulnerability_external_issue_link) { create(:vulnerabilities_external_issue_link, external_issue_key: '10001', vulnerability: vulnerability) }

  let_it_be(:fields) do
    <<~QUERY
      externalIssueLinks {
        nodes {
          id
          linkType
          externalIssue {
            externalTracker
            relativeReference
            status
            title
            webUrl
            createdAt
            updatedAt
          }
        }
      }
    QUERY
  end

  let_it_be(:query) { graphql_query_for('vulnerabilities', {}, query_graphql_field('nodes', {}, fields)) }

  before do
    project.add_developer(user)

    stub_licensed_features(security_dashboard: true, jira_issues_integration: true)
  end

  context 'when queried for the first time with reactive caching' do
    let_it_be(:expected_response) do
      [
        {
          'externalIssueLinks' => {
            'nodes' => [
              {
                'externalIssue' => nil,
                'id' => "gid://gitlab/Vulnerabilities::ExternalIssueLink/#{vulnerability_external_issue_link.id}",
                'linkType' => 'CREATED'
              }
            ]
          }
        }
      ]
    end

    it 'schedules a background job to fetch data from Jira' do
      Sidekiq::Testing.fake! do
        expect { post_graphql(query, current_user: user) }.to change(ExternalServiceReactiveCachingWorker.jobs, :size).by(1)
        expect(ExternalServiceReactiveCachingWorker.jobs.last['args']).to include(project.id, [vulnerability_external_issue_link.external_issue_key])
      end
    end

    it 'returns null as value for externalIssue' do
      post_graphql(query, current_user: user)

      expect(graphql_data['vulnerabilities']['nodes']).to eq(expected_response)
    end
  end

  context 'when queried without reactive caching' do
    let_it_be(:expected_response) do
      [
        {
          'externalIssueLinks' => {
            'nodes' => [
              {
                'externalIssue' => {
                  'createdAt' => '2020-12-16T09:42:03Z',
                  'externalTracker' => 'jira',
                  'relativeReference' => 'GV-100',
                  'status' => 'To Do',
                  'title' => 'Investigate vulnerability: Filesystem function basename() detected with dynamic parameter directly from user input',
                  'updatedAt' => '2020-12-16T09:42:03Z',
                  'webUrl' => 'https://jira.example.com/browse/GV-100'
                },
                'id' => "gid://gitlab/Vulnerabilities::ExternalIssueLink/#{vulnerability_external_issue_link.id}",
                'linkType' => 'CREATED'
              }
            ]
          }
        }
      ]
    end

    let_it_be(:jira_issue_response) do
      {
        total: 1,
        issues: [
          {
            id: '10001',
            key: 'GV-100',
            fields: {
              summary: 'Investigate vulnerability: Filesystem function basename() detected with dynamic parameter directly from user input',
              created: '2020-12-16T10:42:03.071+0100',
              updated: '2020-12-16T10:42:03.071+0100',
              status: {
                name: 'To Do'
              }
            }
          }
        ]
      }.to_json
    end

    before do
      stub_request(:get, /.*10001.*/).to_return(status: 200, body: jira_issue_response, headers: { 'Content-Type' => 'application/json;charset=UTF-8' })

      allow_next_instance_of(Projects::Integrations::Jira::ByIdsFinder) { |by_ids_finder| synchronous_reactive_cache(by_ids_finder) }
    end

    it 'returns a list of all VulnerabilityExternalIssueLink', :sidekiq_inline do
      post_graphql(query, current_user: user)

      expect(graphql_data['vulnerabilities']['nodes']).to eq(expected_response)
    end
  end
end
