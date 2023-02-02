# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::MergeRequestsController, '(JavaScript fixtures in EE context)', type: :controller do
  include JavaScriptFixturesHelpers

  let(:project) { create(:project, :repository, path: 'merge-requests-project') }
  let(:user) { project.first_owner }
  let(:merge_request) { create(:merge_request, source_project: project) }

  render_views

  before do
    sign_in(user)
  end

  it 'ee/merge_requests/merge_request_with_multiple_assignees_feature.html' do
    stub_licensed_features(multiple_merge_request_assignees: true)

    get :show, params: {
      namespace_id: project.namespace.to_param,
      project_id: project,
      id: merge_request.to_param
    }, format: :html

    expect(response).to be_successful
  end

  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers

    let(:variables) { { projectPath: project.full_path, iid: merge_request.iid.to_s } }

    context 'when merge request has no approvals' do
      base_input_path = 'vue_merge_request_widget/components/approvals/queries/'
      base_output_path = 'graphql/merge_requests/approvals/'
      query_name = 'approved_by.query.graphql'

      it "#{base_output_path}#{query_name}_no_approvals.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: true)

        post_graphql(query, current_user: user, variables: variables)

        expect_graphql_errors_to_be_empty
      end
    end

    context 'when merge request is approved by current user' do
      base_input_path = 'vue_merge_request_widget/components/approvals/queries/'
      base_output_path = 'graphql/merge_requests/approvals/'
      query_name = 'approved_by.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        merge_request.approved_by_users << user

        query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: true)

        post_graphql(query, current_user: user, variables: variables)

        expect_graphql_errors_to_be_empty
      end
    end

    context 'when merge request is approved by multiple users' do
      base_input_path = 'vue_merge_request_widget/components/approvals/queries/'
      base_output_path = 'graphql/merge_requests/approvals/'
      query_name = 'approved_by.query.graphql'

      it "#{base_output_path}#{query_name}_multiple_users.json" do
        merge_request.approved_by_users << user
        merge_request.approved_by_users << create(:user)

        query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: true)

        post_graphql(query, current_user: user, variables: variables)

        expect_graphql_errors_to_be_empty
      end
    end

    context 'for merge request getState query' do
      base_input_path = 'vue_merge_request_widget/queries/'
      base_output_path = 'graphql/merge_requests/'
      query_name = 'get_state.query.graphql'

      it "#{base_output_path}#{query_name}.json" do
        query = get_graphql_query_as_string("#{base_input_path}#{query_name}")

        post_graphql(query, current_user: user, variables: variables)

        expect_graphql_errors_to_be_empty
      end
    end

    context 'with merge request approval rules' do
      base_input_path = 'vue_merge_request_widget/components/approvals/queries/'
      base_output_path = 'graphql/merge_requests/approvals/'
      query_name = 'approved_by.query.graphql'

      it "#{base_output_path}#{query_name}_approval_rules.json" do
        stub_licensed_features(multiple_approval_rules: true)

        merge_request.approval_rules <<
          create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 1)
        merge_request.approval_rules <<
          create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 1)
        merge_request.approval_rules <<
          create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 1)

        query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: true)

        post_graphql(query, current_user: user, variables: variables)

        expect_graphql_errors_to_be_empty
      end
    end

    context 'with merge request approvals required' do
      base_input_path = 'vue_merge_request_widget/components/approvals/queries/'
      base_output_path = 'graphql/merge_requests/approvals/'
      query_name = 'approved_by.query.graphql'

      it "#{base_output_path}#{query_name}_approvals_required.json" do
        create(:approval_project_rule, project: project, rule_type: :any_approver, approvals_required: 3)

        query = get_graphql_query_as_string("#{base_input_path}#{query_name}", ee: true)

        post_graphql(query, current_user: user, variables: variables)

        expect_graphql_errors_to_be_empty
      end
    end
  end
end
