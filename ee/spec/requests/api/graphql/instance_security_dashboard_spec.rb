# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.instanceSecurityDashboard.projects', feature_category: :vulnerability_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:other_project) { create(:project) }
  let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }

  before do
    project.add_developer(user)
    other_project.add_developer(user)

    stub_licensed_features(security_dashboard: true)
  end

  let(:query) do
    graphql_query_for(:instance_security_dashboard, dashboard_fields)
  end

  context 'with logged in user' do
    let(:current_user) { user }

    context 'requesting projects in the dashboard' do
      let(:dashboard_fields) { query_graphql_path(%i[projects nodes], 'id') }

      subject(:projects) { graphql_data_at(:instance_security_dashboard, :projects, :nodes) }

      it_behaves_like 'a working graphql query that returns data' do
        before do
          post_graphql(query, current_user: current_user)
        end

        it 'finds only projects that were added to instance security dashboard' do
          expect(projects).to contain_exactly(a_graphql_entity_for(project))
        end
      end
    end

    context 'when loading vulnerabilityGrades alongside with Vulnerability.userNotesCount' do
      let(:fields) do
        <<~QUERY
          allGrades: vulnerabilityGrades {
            grade
            count
            projects {
              nodes {
                vulnerabilities {
                  nodes {
                    id
                    userNotesCount
                  }
                }
              }
            }
          }
          withVulnerabilitiesByState: vulnerabilityGrades {
            grade
            count
            projects {
              nodes {
                confirmedVulnerabilities: vulnerabilities(state: CONFIRMED) {
                  nodes {
                    id
                    userNotesCount
                  }
                }
                dismissedVulnerabilities: vulnerabilities(state: DISMISSED) {
                  nodes {
                    id
                    userNotesCount
                  }
                }
              }
            }
          }
        QUERY
      end

      let(:query) do
        graphql_query_for('instanceSecurityDashboard', nil, fields)
      end

      let_it_be(:vulnerability_1) { create(:vulnerability, :dismissed, :critical_severity, :with_notes, :with_finding, notes_count: 2, project: project) }
      let_it_be(:vulnerability_2) { create(:vulnerability, :confirmed, :high_severity, :with_notes, :with_finding, notes_count: 3, project: project) }
      let_it_be(:vulnerability_3) { create(:vulnerability, :confirmed, :medium_severity, :with_notes, :with_finding, notes_count: 7, project: other_project) }

      let_it_be(:vulnerability_statistic_1) { create(:vulnerability_statistic, :grade_c, project: project) }
      let_it_be(:vulnerability_statistic_2) { create(:vulnerability_statistic, :grade_d, project: other_project) }

      it_behaves_like 'a working graphql query that returns data' do
        let(:expected_response) do
          {
            'allGrades' => [
              {
                'count' => 1,
                'grade' => 'C',
                'projects' => {
                  'nodes' => [
                    {
                      'vulnerabilities' => {
                        'nodes' => [
                          { 'id' => vulnerability_1.to_global_id.to_s, 'userNotesCount' => 2 },
                          { 'id' => vulnerability_2.to_global_id.to_s, 'userNotesCount' => 3 }
                        ]
                      }
                    }
                  ]
                }
              },
              {
                'count' => 1,
                'grade' => 'D',
                'projects' => {
                  'nodes' => [
                    {
                      'vulnerabilities' => {
                        'nodes' => [
                          { 'id' => vulnerability_3.to_global_id.to_s, 'userNotesCount' => 7 }
                        ]
                      }
                    }
                  ]
                }
              }
            ],
            'withVulnerabilitiesByState' => [
              {
                'count' => 1,
                'grade' => 'C',
                'projects' => {
                  'nodes' => [
                    {
                      'confirmedVulnerabilities' => {
                        'nodes' => [
                          { 'id' => vulnerability_2.to_global_id.to_s, 'userNotesCount' => 3 }
                        ]
                      },
                      'dismissedVulnerabilities' => {
                        'nodes' => [
                          { 'id' => vulnerability_1.to_global_id.to_s, 'userNotesCount' => 2 }
                        ]
                      }
                    }
                  ]
                }
              },
              {
                'count' => 1,
                'grade' => 'D',
                'projects' => {
                  'nodes' => [
                    {
                      'confirmedVulnerabilities' => {
                        'nodes' => [
                          { 'id' => vulnerability_3.to_global_id.to_s, 'userNotesCount' => 7 }
                        ]
                      },
                      'dismissedVulnerabilities' => { 'nodes' => [] }
                    }
                  ]
                }
              }
            ]
          }
        end

        before do
          user.security_dashboard_projects << other_project

          post_graphql(query, current_user: current_user)
        end

        it 'finds vulnerability grades for only projects that were added to instance security dashboard', :aggregate_failures do
          expect(graphql_data.dig('instanceSecurityDashboard', 'allGrades')).to match_array(expected_response['allGrades'])
          expect(graphql_data.dig('instanceSecurityDashboard', 'withVulnerabilitiesByState')).to match_array(expected_response['withVulnerabilitiesByState'])
        end
      end
    end

    context 'requesting clusterAgents in the dashboard' do
      let_it_be(:other_project_without_access) { create(:project) }

      let_it_be(:cluster_agent) { create(:cluster_agent, project: project) }
      let_it_be(:cluster_agent_for_other_agent) { create(:cluster_agent, project: other_project_without_access) }

      let(:dashboard_fields) { query_graphql_path(%i[clusterAgents nodes], 'id') }

      subject(:cluster_agents) { graphql_data_at(:instance_security_dashboard, :cluster_agents, :nodes) }

      it_behaves_like 'a working graphql query that returns data' do
        before do
          user.security_dashboard_projects << other_project_without_access

          post_graphql(query, current_user: current_user)
        end

        it 'finds only projects that were added to instance security dashboard' do
          expect(cluster_agents).to contain_exactly(a_graphql_entity_for(cluster_agent))
        end
      end
    end
  end

  context 'with no user' do
    let(:current_user) { nil }

    let(:dashboard_fields) { nil }

    it_behaves_like 'a working graphql query that returns no data' do
      before do
        post_graphql(query, current_user: current_user)
      end
    end
  end
end
