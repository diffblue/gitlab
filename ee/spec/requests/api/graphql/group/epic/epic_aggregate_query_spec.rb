# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Epic aggregates (count and weight)', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:ancestor) { create(:group, :public) }
  let_it_be(:group) { create(:group, :public, parent: ancestor) }
  let_it_be(:parent_epic) { create(:epic, group: ancestor, title: 'parent epic') }

  let(:target_epic) { parent_epic }
  let(:query) do
    graphql_query_for('group', { fullPath: target_epic.group.full_path }, query_graphql_field('epics', { iid: target_epic.iid }, epic_aggregates_query))
  end

  let(:epic_aggregates_query) do
    <<~QUERY
      nodes {
        descendantWeightSum {
          openedIssues
          closedIssues
        }
        descendantCounts {
          openedEpics
          closedEpics
          openedIssues
          closedIssues
        }
      }
    QUERY
  end

  before do
    stub_licensed_features(epics: true)
  end

  context 'count and weight totals' do
    subject { graphql_data.dig('group', 'epics', 'nodes') }

    let_it_be(:subgroup) { create(:group, :private, parent: group) }
    let_it_be(:project) { create(:project, namespace: group) }

    let_it_be(:epic_with_issues) { create(:epic, group: group, parent: parent_epic, title: 'epic with issues') }
    let_it_be(:epic_without_issues) { create(:epic, :closed, group: group, parent: parent_epic, title: 'epic without issues') }
    let_it_be(:closed_epic) { create(:epic, :closed, group: group, parent: parent_epic, title: 'closed epic') }

    let_it_be(:issue1) { create(:issue, project: project, weight: 5, state: :opened) }
    let_it_be(:issue2) { create(:issue, project: project, weight: 7, state: :closed) }
    let_it_be(:issue3) { create(:issue, project: project, weight: 0) }

    let_it_be(:epic_issue1) { create(:epic_issue, epic: epic_with_issues, issue: issue1) }
    let_it_be(:epic_issue2) { create(:epic_issue, epic: epic_with_issues, issue: issue2) }
    let_it_be(:epic_issue3) { create(:epic_issue, epic: parent_epic, issue: issue3) }

    before do
      group.add_developer(current_user)
      post_graphql(query, current_user: current_user)
    end

    shared_examples 'counts properly' do
      it_behaves_like 'a working graphql query'

      it 'returns the epic counts' do
        epic_count_result = {
          "openedEpics" => 1,
          "closedEpics" => 2
        }

        is_expected.to include(
          a_hash_including('descendantCounts' => a_hash_including(epic_count_result))
        )
      end

      it 'returns the issue counts' do
        issue_count_result = {
          "openedIssues" => 2,
          "closedIssues" => 1
        }

        is_expected.to include(
          a_hash_including('descendantCounts' => a_hash_including(issue_count_result))
        )
      end
    end

    shared_examples 'having correct values for' do |field_name|
      let(:epic_aggregates_query) do
        <<~QUERY
          nodes {
            #{field_name}
          }
        QUERY
      end

      it_behaves_like 'a working graphql query'

      context 'when target epic has child epics or issues' do
        let(:target_epic) { parent_epic }

        it 'returns true' do
          post_graphql(query, current_user: current_user)

          expect(subject).to include(a_hash_including(field_name => true))
        end
      end

      context 'when target epic has no child epics nor issues' do
        let(:target_epic) { epic_without_issues }

        it 'returns false' do
          post_graphql(query, current_user: current_user)

          expect(subject).to include(a_hash_including(field_name => false))
        end
      end
    end

    shared_examples 'efficient query' do
      it 'does not result in N+1' do
        control_count = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: current_user) }.count

        query_with_multiple_epics = graphql_query_for('group', { fullPath: epic_with_issues.group.full_path }, query_graphql_field('epics', { iids: [epic_with_issues.iid, epic_without_issues.iid, parent_epic.iid] }, epic_aggregates_query))

        # We still get multiple of these lines
        # Group Load (0.6ms)  SELECT "namespaces".* FROM "namespaces" WHERE "namespaces"."type" = 'Group' AND "namespaces"."id" = x LIMIT 1
        #   -> ee/app/policies/epic_policy.rb:4:in `block in <class:EpicPolicy>'
        # So I'll add n to this number to take this into account.
        # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/27551#note_307716428
        expect { post_graphql(query_with_multiple_epics, current_user: current_user) }.not_to exceed_query_limit(control_count + 2)
      end
    end

    it 'uses the LazyEpicAggregate service' do
      # one for count, one for weight_sum, even though the share the same tree state as part of the context
      expect(Gitlab::Graphql::Aggregations::Epics::LazyEpicAggregate).to receive(:new).twice

      post_graphql(query, current_user: current_user)
    end

    it_behaves_like 'counts properly'

    it 'returns the weights' do
      descendant_weight_result = {
        "openedIssues" => 5,
        "closedIssues" => 7
      }

      is_expected.to include(
        a_hash_including('descendantWeightSum' => a_hash_including(descendant_weight_result))
      )
    end

    context 'when requesting has_issues' do
      let(:epic_aggregates_query) do
        <<~QUERY
          nodes {
            hasIssues
          }
        QUERY
      end

      it_behaves_like 'having correct values for', 'hasIssues'
      it_behaves_like 'efficient query'
    end

    context 'when requesting has_children' do
      let(:epic_aggregates_query) do
        <<~QUERY
          nodes {
            hasChildren
          }
        QUERY
      end

      it_behaves_like 'having correct values for', 'hasChildren'
      it_behaves_like 'efficient query'
    end
  end
end
