# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creating an External Issue Link', feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project) }
  let_it_be(:finding) { create(:vulnerabilities_finding, :with_pipeline, project: project, severity: :high) }
  let_it_be(:vulnerability) { create(:vulnerability, title: 'My vulnerability', project: project, findings: [finding]) }
  let_it_be(:external_provider) { 'jira' }

  let(:mutation) do
    params = { id: vulnerability.to_global_id.to_s, link_type: 'CREATED', external_tracker: 'JIRA' }

    graphql_mutation(:vulnerability_external_issue_link_create, params)
  end

  def mutation_response
    graphql_mutation_response(:vulnerability_external_issue_link_create)
  end

  context 'when the user does not have permission' do
    before do
      stub_licensed_features(security_dashboard: true, jira_vulnerabilities_integration: true)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not create external issue link' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(Vulnerabilities::ExternalIssueLink, :count)
    end
  end

  context 'when the user has permission' do
    before do
      vulnerability.project.add_developer(current_user)
    end

    context 'when security_dashboard is disabled' do
      before do
        stub_licensed_features(security_dashboard: false)
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ['The resource that you are attempting to access does not '\
                 'exist or you don\'t have permission to perform this action']
    end

    context 'when security_dashboard is enabled' do
      before do
        stub_licensed_features(security_dashboard: true, jira_vulnerabilities_integration: true)
      end

      context 'when jira is not configured' do
        it 'responds with error' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response['errors']).to eq(['External provider service is not configured to create issues.'])
        end
      end

      context 'when jira is configured' do
        let!(:jira_integration) { create(:jira_integration, project: vulnerability.project, vulnerabilities_enabled: true, project_key: 'GV', vulnerabilities_issuetype: '10000') }

        context 'when issue creation succeeds' do
          before do
            stub_request(:get, 'https://jira.example.com/rest/api/2/project/GV').to_return(status: 200, body: { 'id' => '10000' }.to_json)
            stub_request(:post, 'https://jira.example.com/rest/api/2/issue')
              .to_return(
                status: 200,
                body: jira_created_issue.to_json
              )
          end

          let(:jira_created_issue) do
            {
              'id' => external_issue_id,
              fields: {
                project: { id: '11223' },
                issuetype: { id: '10001' },
                summary: 'Special Summary!?',
                description: "*ID*: 2\n_Issue_: !",
                created: '2020-06-25T15:39:30.000+0000',
                updated: '2020-06-26T15:38:32.000+0000',
                resolutiondate: '2020-06-27T13:23:51.000+0000',
                labels: ['backend'],
                status: { name: 'To Do' },
                key: 'GV-5',
                assignee: nil,
                reporter: { name: 'admin', displayName: 'Admin' }
              }
            }
          end

          context 'and saving external issue link succeeds' do
            let(:external_issue_id) { '10000' }

            it 'creates the external issue link and returns nil for external issue to be fetched using query', :aggregate_failures do
              expect { post_graphql_mutation(mutation, current_user: current_user) }.to change(Vulnerabilities::ExternalIssueLink, :count).by(1)
              expect(mutation_response['errors']).to be_empty
              expect(mutation_response.dig('externalIssueLink', 'externalIssue')).to be_nil
            end
          end

          context 'and saving external issue link fails' do
            let(:external_issue_id) { nil }

            it 'creates the external issue link' do
              expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(Vulnerabilities::ExternalIssueLink, :count)
            end
          end
        end

        context 'when issue creation fails' do
          before do
            stub_request(:get, 'https://jira.example.com/rest/api/2/project/GV').to_return(status: 200, body: { 'id' => '10000' }.to_json)
            stub_request(:post, 'https://jira.example.com/rest/api/2/issue').to_return(status: 400, body: { 'errors' => ['bad request'] }.to_json)
          end

          it 'does not create the external issue link' do
            expect { post_graphql_mutation(mutation, current_user: current_user) }.not_to change(Vulnerabilities::ExternalIssueLink, :count)
          end
        end
      end
    end
  end
end
