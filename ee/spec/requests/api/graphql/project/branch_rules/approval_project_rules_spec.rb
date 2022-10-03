# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting approval project rules for a branch rule' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:branch_rule) { create(:protected_branch) }
  let_it_be(:project) { branch_rule.project }
  let_it_be(:approval_project_rule) do
    create(:approval_project_rule,
           :requires_approval,
           :license_scanning,
           project: project,
           protected_branches: [branch_rule],
           users: [current_user])
  end

  let(:variables) { { path: project.full_path } }
  let(:fields) { all_graphql_fields_for('ApprovalProjectRule') }
  let(:approval_project_rule_data) { approval_project_rules_data.first }
  let(:branch_rules_data) { graphql_data_at('project', 'branchRules', 'nodes') }
  let(:approval_project_rules_data) do
    graphql_data_at('project', 'branchRules', 'nodes', 0, 'approvalRules', 'nodes')
  end

  let(:query) do
    <<~GQL
    query($path: ID!) {
      project(fullPath: $path) {
        branchRules {
          nodes {
            approvalRules {
              nodes {
                #{fields}
              }
            }
          }
        }
      }
    }
    GQL
  end

  context 'when the user does not have read_approval_rule abilities' do
    before do
      project.add_guest(current_user)
      post_graphql(query, current_user: current_user, variables: variables)
    end

    it_behaves_like 'a working graphql query' do
      it 'hides approval rule data' do
        expect(approval_project_rules_data).not_to be_present
      end
    end
  end

  context 'when the user does have read_approval_rule abilities' do
    before do
      project.add_maintainer(current_user)
      post_graphql(query, current_user: current_user, variables: variables)
    end

    it_behaves_like 'a working graphql query' do
      it 'returns all approval project rule data' do
        expect(approval_project_rules_data).to be_an Array
        expect(approval_project_rules_data.size).to eq(1)

        expect(approval_project_rule_data['name']).to eq(approval_project_rule.name)

        expect(approval_project_rule_data['type']).to eq(approval_project_rule.rule_type.to_s.upcase)

        expect(approval_project_rule.approvers.count).to eq(1)
        expect(graphql_dig_at(approval_project_rule_data, 'approvalsRequired'))
          .to eq(approval_project_rule.approvals_required)

        eligible_approvers = graphql_dig_at(approval_project_rule_data, 'eligibleApprovers', 'nodes')
        expect(eligible_approvers.count).to eq(1)
        expect(eligible_approvers.first['name']).to eq(approval_project_rule.approvers.first.name)
      end
    end
  end
end
