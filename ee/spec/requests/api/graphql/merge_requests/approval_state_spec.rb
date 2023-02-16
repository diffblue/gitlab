# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project.mergeRequest.approvalState', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be_with_refind(:current_user) { create(:user) }

  context 'when requesting information about approval state' do
    let_it_be_with_refind(:user) { create(:user) }
    let_it_be_with_refind(:group) { create(:group) }
    let_it_be_with_refind(:project) { create(:project, :public, :repository, group: group) }
    let_it_be_with_refind(:merge_request) { create(:merge_request, source_project: project) }

    let_it_be_with_refind(:fields) do
      <<~QUERY
        approvalState {
          approvalRulesOverwritten
          rules {
            id
            name
            type
            approvalsRequired
            approved
            containsHiddenGroups
            overridden
            section
            eligibleApprovers {
              id
            }
            users {
              nodes {
                id
              }
            }
            sourceRule {
              id
            }
            approvedBy {
              nodes {
                id
              }
            }
            groups {
              nodes {
                id
              }
            }
            commentedBy {
              nodes {
                id
              }
            }
          }
          invalidApproversRules {
            id
          }
          suggestedApprovers {
            nodes {
              id
            }
          }
        }
      QUERY
    end

    let(:query) do
      graphql_query_for(
        :project,
        { full_path: project.full_path },
        query_graphql_field(
          :merge_request,
          { iid: merge_request.iid.to_s },
          fields
        )
      )
    end

    let(:approval_state) do
      graphql_data_at(:project,
                      :merge_request,
                      :approval_state)
    end

    before do
      merge_request.reviewers << user
    end

    context 'when no approval rule is set to the MR' do
      it 'returns null data' do
        post_graphql(query)

        expect(approval_state).to eq(
          'approvalRulesOverwritten' => false,
          'invalidApproversRules' => [],
          'rules' => [],
          'suggestedApprovers' => {
            'nodes' => []
          }
        )
      end
    end

    context 'when the MR has approval rules configured' do
      let(:code_owner_rule) { create(:code_owner_rule, merge_request: merge_request) }

      before do
        stub_licensed_features(merge_request_approvers: true)
        code_owner_rule.users << user
      end

      it 'returns appropriate data' do
        post_graphql(query)

        expect(approval_state).to match a_hash_including(
          'approvalRulesOverwritten' => false,
          'invalidApproversRules' => [],
          'rules' => contain_exactly(
            a_graphql_entity_for(
              code_owner_rule, :name,
              'approvalsRequired' => 0,
              'approved' => true,
              'approvedBy' => { 'nodes' => [] },
              'commentedBy' => { 'nodes' => [] },
              'containsHiddenGroups' => false,
              'eligibleApprovers' => contain_exactly(a_graphql_entity_for(user)),
              'groups' => { 'nodes' => [] },
              'overridden' => false,
              'section' => 'codeowners',
              'sourceRule' => nil,
              'type' => 'CODE_OWNER',
              'users' => { 'nodes' => contain_exactly(a_graphql_entity_for(user)) }
            )
          ),
          'suggestedApprovers' => {
            'nodes' => contain_exactly(a_graphql_entity_for(user))
          }
        )
      end

      context 'when there are commented approvers' do
        before do
          create(
            :diff_note_on_merge_request,
            author: user,
            noteable: merge_request,
            project: merge_request.project
          )
        end

        it 'returns appropriate data' do
          post_graphql(query)

          expect(approval_state).to match a_hash_including(
            'rules' => contain_exactly(
              a_graphql_entity_for(
                code_owner_rule,
                'commentedBy' => {
                  'nodes' => contain_exactly(a_graphql_entity_for(user))
                }
              )
            )
          )
        end
      end
    end

    context 'when there are invalid approvers rules' do
      let!(:invalid_approvers_rule) do
        create(
          :approval_merge_request_rule,
          merge_request: merge_request,
          approvals_required: 1
        )
      end

      before do
        stub_licensed_features(merge_request_approvers: true)
      end

      it 'returns appropriate data' do
        post_graphql(query)

        expect(approval_state).to match a_hash_including(
          'invalidApproversRules' => [
            a_graphql_entity_for(invalid_approvers_rule)
          ]
        )
      end
    end
  end
end
