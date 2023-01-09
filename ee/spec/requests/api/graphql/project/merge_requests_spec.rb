# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting merge request listings (EE) nested in a project', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:merge_request_a) { create(:merge_request, :unique_branches, source_project: project) }
  let_it_be(:merge_request_b) { create(:merge_request, :closed, :unique_branches, source_project: project) }
  let_it_be(:merge_request_c) { create(:merge_request, :closed, :unique_branches, source_project: project) }

  let(:results) { graphql_data.dig('project', 'mergeRequests', 'nodes') }

  let(:query) do
    query_merge_requests(all_graphql_fields_for('MergeRequest', max_depth: 1))
  end

  def query_merge_requests(fields)
    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_graphql_field(:merge_requests, search_params, [query_graphql_field(:nodes, nil, fields)])
    )
  end

  def execute_query
    query = query_merge_requests(requested_fields)
    post_graphql(query, current_user: current_user)
  end

  context 'when requesting approval fields' do
    let(:search_params) { { iids: [merge_request_a.iid.to_s] } }
    let(:requested_fields) { [:approved, :approvals_left, :approvals_required] }
    let(:approval_state) { instance_double(ApprovalState, approvals_required: 5, approvals_left: 3, approved?: false) }

    before do
      allow_next_found_instance_of(MergeRequest) do |mr|
        allow(mr).to receive(:approval_state).and_return(approval_state)
      end
    end

    it 'exposes approval metadata' do
      execute_query

      expect(results).to eq([
                              {
                                'approved' => false,
                                'approvalsLeft' => 3,
                                'approvalsRequired' => 5
                              }
                            ])
    end
  end
end
