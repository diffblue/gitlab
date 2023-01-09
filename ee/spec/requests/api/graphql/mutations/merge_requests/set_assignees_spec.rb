# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting assignees of a merge request', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, developer_projects: [project]) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:assignees) { create_list(:user, 3, developer_projects: [project]) }
  let_it_be(:extra_assignees) { create_list(:user, 2, developer_projects: [project]) }

  let(:input) { { assignee_usernames: assignees.map(&:username) } }
  let(:expected_result) do
    assignees.map { |u| { 'username' => u.username } }
  end

  def mutation(vars = input, mr = merge_request)
    variables = vars.merge(project_path: mr.project.full_path, iid: mr.iid.to_s)

    graphql_mutation(:merge_request_set_assignees, variables, <<-QL.strip_heredoc)
      clientMutationId
      errors
      mergeRequest {
        id
        assignees {
          nodes {
            username
          }
        }
      }
    QL
  end

  def mutation_response
    graphql_mutation_response(:merge_request_set_assignees)
  end

  def mutation_assignee_nodes
    mutation_response['mergeRequest']['assignees']['nodes']
  end

  before do
    [current_user, *assignees, *extra_assignees].each do |user|
      project.add_developer(user)
    end
  end

  it 'adds the assignees to the merge request' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_assignee_nodes).to match_array(expected_result)
  end

  context 'with assignees already assigned' do
    before do
      merge_request.assignees = extra_assignees
      merge_request.save!
    end

    it 'removes assignees not in the list' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_assignee_nodes).to match_array(expected_result)
    end
  end

  context 'when passing append as true' do
    let(:mode) { Types::MutationOperationModeEnum.enum[:append] }
    let(:usernames) { assignees.map(&:username) }
    let(:input) { { operation_mode: mode } }

    let(:expected_result) do
      (assignees + extra_assignees).map { |u| { 'username' => u.username } }
    end

    before do
      merge_request.reload
      merge_request.assignees = extra_assignees
      merge_request.save!
    end

    it 'does not remove users not in the list' do
      vars = input.merge(assignee_usernames: usernames)
      post_graphql_mutation(mutation(vars), current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_assignee_nodes).to match_array(expected_result)
    end

    describe 'performance' do
      it 'is scalable' do
        mr_a = create(:merge_request, :unique_branches, source_project: project)
        mr_b = create(:merge_request, :unique_branches, source_project: project)

        add_one_assignee = mutation(input.merge(assignee_usernames: usernames.take(1)), mr_a)
        add_two_assignees = mutation(input.merge(assignee_usernames: usernames.last(2)), mr_b)

        baseline = ActiveRecord::QueryRecorder.new do
          post_graphql_mutation(add_one_assignee, current_user: current_user)
        end

        # given the way ActiveRecord implements MergeRequest#assignee_ids=(ids),
        # we to live with a slight inefficiency here:
        # For each ID, AR issues:
        #   - SELECT 1 AS one FROM "merge_request_assignees"...
        # Followed by:
        #   - INSERT INTO "merge_request_assignees" ("user_id", "merge_request_id", "created_at")...
        # On top of which, we have to do an extra authorization fetch
        expect do
          post_graphql_mutation(add_two_assignees, current_user: current_user)
        end.not_to exceed_query_limit(baseline.count + 3)
      end
    end
  end
end
