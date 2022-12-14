# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting an issue list at root level', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group1) { create(:group).tap { |group| group.add_developer(current_user) } }
  let_it_be(:group2) { create(:group).tap { |group| group.add_developer(current_user) } }
  let_it_be(:project_a) { create(:project, :repository, :public, group: group1) }
  let_it_be(:project_b) { create(:project, :repository, :private, group: group1) }
  let_it_be(:project_c) { create(:project, :repository, :public, group: group2) }
  let_it_be(:project_d) { create(:project, :repository, :private, group: group2) }
  let_it_be(:public_project) { project_a }
  let_it_be(:issue_a) { create(:issue, project: project_a) }
  let_it_be(:issue_b) { create(:issue, project: project_b, weight: 1) }
  let_it_be(:issue_c) { create(:issue, project: project_c, weight: 2) }
  let_it_be(:issue_d) { create(:issue, project: project_d, weight: 3) }
  let_it_be(:issue_e) { create(:issue, project: project_d, weight: 4) }

  let(:issue_filter_params) { {} }
  let(:issues) { [issue_a, issue_b, issue_c, issue_d, issue_e] }
  let(:fields) do
    <<~QUERY
      nodes { id }
    QUERY
  end

  # All new specs should be added to the shared example if the change also
  # affects the `issues` query at the project level of the API.
  # Shared example also used in ee/spec/requests/api/graphql/project/issues_spec.rb
  it_behaves_like 'graphql issue list request spec EE' do
    let(:issue_nodes_path) { %w[issues nodes] }

    # sorting
    let(:data_path) { [:issues] }

    def pagination_query(params)
      graphql_query_for(
        :issues,
        params,
        "#{page_info} nodes { id }"
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
      :issues,
      params,
      fields
    )
  end
end
