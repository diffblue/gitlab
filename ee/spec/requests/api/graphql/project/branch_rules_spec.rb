# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting list of branch rules for a project', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:current_user) { create(:user, maintainer_projects: [project]) }
  let_it_be(:approval_rule) { create(:approval_project_rule, project: project) }
  let_it_be(:branch_rule) { create(:protected_branch, project: project, approval_project_rules: [approval_rule]) }

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
      post_graphql(query, current_user: current_user, variables: variables)
    end

    it_behaves_like 'a working graphql query' do
      it 'returns approval_rules' do
        expect(branch_rule_data['approvalRules']['nodes']).to eq(
          [{
            'id' => approval_rule.to_global_id.to_s,
            'name' => approval_rule.name,
            'type' => approval_rule.rule_type.upcase,
            'approvalsRequired' => approval_rule.approvals_required
          }])
      end
    end
  end
end
