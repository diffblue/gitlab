# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting list of branch rules for a project' do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:branch_rule) do
    create(:protected_branch, project: project).tap do |protected_branch|
      apr = create(:approval_project_rule, project: project)
      protected_branch.approval_project_rules << apr
    end
  end

  let(:branch_rule_data) { graphql_data_at('project', 'branchRules', 'nodes', 0) }
  let(:variables) { { path: project.full_path } }
  let(:fields) { all_graphql_fields_for('BranchRule') }
  let(:query) do
    <<~GQL
    query($path: ID!, $n: Int, $cursor: String) {
      project(fullPath: $path) {
        branchRules(first: $n, after: $cursor) {
          nodes {
            #{fields}
          }
        }
      }
    }
    GQL
  end

  context 'when the user does have read_protected_branch abilities' do
    before do
      project.add_maintainer(current_user)
      post_graphql(query, current_user: current_user, variables: variables)
    end

    it_behaves_like 'a working graphql query' do
      it 'returns approval_rules' do
        expect(branch_rule_data['approvalRules']).to be_present
      end
    end
  end
end
