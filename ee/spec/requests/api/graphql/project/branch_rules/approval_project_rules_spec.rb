# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting approval project rules for a branch rule', feature_category: :source_code_management do
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
                #{all_graphql_fields_for('ApprovalProjectRule')}
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

    it_behaves_like 'a working graphql query', :aggregate_failures do
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

      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new do
          post_graphql(query, current_user: current_user, variables: variables)
        end.count

        number_of_rules = 3

        create_list(:approval_project_rule, number_of_rules, :requires_approval,
          project: project, protected_branches: [branch_rule], users: [current_user])

        expect do
          post_graphql(query, current_user: current_user, variables: variables)
        end.not_to exceed_query_limit(control).with_threshold(number_of_rules * 2) # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/376723
      end
    end
  end
end
