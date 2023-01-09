# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'MergeRequestReviewer', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  context 'when requesting information about MR interactions' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project, :public, :repository) }
    let_it_be(:merge_request) { create(:merge_request, source_project: project) }

    let(:query) do
      graphql_query_for(
        :project,
        { full_path: project.full_path },
        query_graphql_field(
          :merge_request,
          { iid: merge_request.iid.to_s },
          query_nodes(
            :reviewers,
            "mergeRequestInteraction { #{all_graphql_fields_for('UserMergeRequestInteraction')} }"
          )
        )
      )
    end

    let(:interaction) do
      graphql_data_at(:project,
                      :merge_request,
                      :reviewers,
                      :nodes, 0,
                      :merge_request_interaction)
    end

    before do
      merge_request.reviewers << user
    end

    context 'when the user does not have any applicable rules' do
      it 'returns null data' do
        post_graphql(query)

        expect(interaction).to include(
          'applicableApprovalRules' => []
        )
      end
    end

    context 'when the user has interacted' do
      let(:rule) { create(:code_owner_rule, merge_request: merge_request) }

      before do
        stub_licensed_features(merge_request_approvers: true)
        rule.users << user
      end

      it 'returns appropriate data' do
        the_rule = a_graphql_entity_for(
          rule, :name,
          'type' => 'CODE_OWNER',
          'approvalsRequired' => 0,
          'approved' => true,
          'containsHiddenGroups' => false,
          'overridden' => false,
          'section' => 'codeowners',
          'sourceRule' => nil
        )

        post_graphql(query)

        expect(interaction['applicableApprovalRules'].first).to match the_rule
      end
    end
  end
end
