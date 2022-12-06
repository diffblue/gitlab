# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting an issue list for a project', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project).tap { |project| project.add_developer(current_user) } }
  let_it_be(:public_project) { project }
  let_it_be(:issue_a) { create(:issue, project: project) }
  let_it_be(:issue_b) { create(:issue, project: project, weight: 1) }
  let_it_be(:issue_c) { create(:issue, project: project, weight: 2) }
  let_it_be(:issue_d) { create(:issue, project: project, weight: 3) }
  let_it_be(:issue_e) { create(:issue, project: project, weight: 4) }

  let(:issue_filter_params) { {} }
  let(:issues) { [issue_a, issue_b, issue_c, issue_d, issue_e] }

  # All new specs should be added to the shared example if the change also
  # affects the `issues` query at the root level of the API.
  # Shared example also used in ee/spec/requests/api/graphql/issues_spec.rb
  it_behaves_like 'graphql issue list request spec EE' do
    let(:issue_nodes_path) { %w[project issues nodes] }

    # sorting
    let(:data_path) { [:project, :issues] }

    def pagination_query(params)
      graphql_query_for(
        :project,
        { full_path: project.full_path },
        query_nodes(:issues, :id, args: params, include_pagination_info: true)
      )
    end
  end

  def execute_query
    post_query
  end

  def post_query(request_user = current_user)
    post_graphql(query, current_user: request_user)
  end

  def query(params = issue_filter_params)
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('issues', params, fields)
    )
  end

  describe 'filtered' do
    context 'by negated health status' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:issue_at_risk) { create(:issue, health_status: :at_risk, project: project) }
      let_it_be(:issue_needs_attention) { create(:issue, health_status: :needs_attention, project: project) }

      let(:params) { { not: { health_status_filter: :atRisk } } }
      let(:query) do
        graphql_query_for(:project, { full_path: project.full_path },
          query_nodes(:issues, :id, args: params)
        )
      end

      it 'only returns issues without the negated health status' do
        post_graphql(query, current_user: current_user)

        issues = graphql_data.dig('project', 'issues', 'nodes')

        expect(issues.size).to eq(1)
        expect(issues.first["id"]).to eq(issue_needs_attention.to_global_id.to_s)
      end
    end
  end
end
