# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an approval_rule', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, developer_projects: [project]) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:users) { create_list(:user, 3, developer_projects: [project]) }
  let_it_be(:extra_users) { create_list(:user, 2, developer_projects: [project]) }
  let_it_be(:rule) do
    create(:approval_merge_request_rule, name: "test-rule", merge_request: merge_request, approvals_required: 1)
  end

  def mutation(vars = input, mr = merge_request)
    variables = vars.reverse_merge(project_path: mr.project.full_path, iid: mr.iid.to_s, approval_rule_id: rule.id,
      approvals_required: 1, name: "test-rule", user_ids: users.pluck(:id).map!(&:to_s))

    graphql_mutation(:merge_request_update_approval_rule, variables, <<-QL.strip_heredoc)
        errors
    QL
  end

  def mutation_response
    graphql_mutation_response(:merge_request_update_approval_rule)
  end

  before do
    [current_user, *users, *extra_users].each { |user| project.add_developer(user) }
  end

  context "with approvals_required" do
    let(:input) { { approvals_required: 2 } }

    it 'sets two required approvals to merge request rule' do
      post_graphql_mutation(mutation(input), current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(rule.reload.approvals_required).to eq(2)
    end
  end

  context 'with users already assigned' do
    let(:input) { { user_ids: (users + extra_users).pluck(:id).map!(&:to_s) } }

    it 'adds extra users' do
      post_graphql_mutation(mutation(input), current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(rule.users).to match_array(users + extra_users)
    end
  end
end
