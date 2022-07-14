# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting an issue list for a project' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  describe 'sorting and pagination' do
    let_it_be(:sort_project) { create(:project, :public) }

    let(:data_path) { [:project, :issues] }

    def pagination_query(params)
      graphql_query_for(:project, { full_path: sort_project.full_path },
        query_nodes(:issues, :iid, args: params, include_pagination_info: true)
      )
    end

    context 'when sorting by weight' do
      let_it_be(:weight_issue1) { create(:issue, project: sort_project, weight: 5) }
      let_it_be(:weight_issue2) { create(:issue, project: sort_project, weight: nil) }
      let_it_be(:weight_issue3) { create(:issue, project: sort_project, weight: 1) }
      let_it_be(:weight_issue4) { create(:issue, project: sort_project, weight: nil) }
      let_it_be(:weight_issue5) { create(:issue, project: sort_project, weight: 3) }

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:node_path) { %w[iid] }
          let(:sort_param) { :WEIGHT_ASC }
          let(:first_param) { 2 }
          let(:all_records) { [weight_issue3, weight_issue5, weight_issue1, weight_issue4, weight_issue2].map { |i| i.iid.to_s } }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:node_path) { %w[iid] }
          let(:sort_param) { :WEIGHT_DESC }
          let(:first_param) { 2 }
          let(:all_records) { [weight_issue1, weight_issue5, weight_issue3, weight_issue4, weight_issue2].map { |i| i.iid.to_s } }
        end
      end
    end

    context 'when sorting by published incident' do
      let_it_be(:published_issue1) { create(:issue, project: sort_project) }
      let_it_be(:published_issue2) { create(:issue, project: sort_project) }
      let_it_be(:published_issue3) { create(:issue, project: sort_project) }
      let_it_be(:published_issue4) { create(:issue, project: sort_project) }
      let_it_be(:published_issue5) { create(:issue, project: sort_project) }

      before(:all) do
        create(:status_page_published_incident, issue: published_issue1)
        create(:status_page_published_incident, issue: published_issue5)
      end

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:node_path) { %w[iid] }
          let(:sort_param)       { :PUBLISHED_ASC }
          let(:first_param)      { 2 }
          let(:all_records) { [published_issue4, published_issue3, published_issue2, published_issue5, published_issue1].map { |i| i.iid.to_s } }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:node_path) { %w[iid] }
          let(:sort_param)       { :PUBLISHED_DESC }
          let(:first_param)      { 2 }
          let(:all_records) { [published_issue1, published_issue5, published_issue4, published_issue3, published_issue2].map { |i| i.iid.to_s } }
        end
      end
    end

    context 'when sorting by sla due' do
      let_it_be(:sla_issue1) { create(:issue, :incident, project: sort_project) }
      let_it_be(:sla_issue2) { create(:issue, :incident, project: sort_project) }
      let_it_be(:sla_issue3) { create(:issue, :incident, project: sort_project) }
      let_it_be(:sla_issue4) { create(:issue, :incident, project: sort_project) }
      let_it_be(:sla_issue5) { create(:issue, :incident, project: sort_project) }

      before(:all) do
        create(:issuable_sla, issue: sla_issue1, due_at: 1.month.ago)
        create(:issuable_sla, issue: sla_issue5, due_at: 2.months.ago)
      end

      context 'when ascending' do
        it_behaves_like 'sorted paginated query' do
          let(:node_path) { %w[iid] }
          let(:sort_param)       { :SLA_DUE_AT_ASC }
          let(:first_param)      { 2 }
          let(:all_records) { [sla_issue5, sla_issue1, sla_issue4, sla_issue3, sla_issue2].map { |i| i.iid.to_s } }
        end
      end

      context 'when descending' do
        it_behaves_like 'sorted paginated query' do
          let(:node_path) { %w[iid] }
          let(:sort_param)       { :SLA_DUE_AT_DESC }
          let(:first_param)      { 2 }
          let(:all_records) { [sla_issue1, sla_issue5, sla_issue4, sla_issue3, sla_issue2].map { |i| i.iid.to_s } }
        end
      end
    end
  end

  describe 'blocked' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:unrelated_issue) { create(:issue, project: project) }
    let_it_be(:blocked_issue1) { create(:issue, project: project) }
    let_it_be(:blocking_issue1) { create(:issue, project: project) }
    let_it_be(:blocked_issue2) { create(:issue, project: project) }
    let_it_be(:blocking_issue2) { create(:issue, :confidential, project: project) }
    let_it_be(:blocking_issue3) { create(:issue, project: project) }

    let_it_be(:issue_link1) { create(:issue_link, source: blocking_issue1, target: blocked_issue1, link_type: 'blocks') }
    let_it_be(:issue_link2) { create(:issue_link, source: blocking_issue2, target: blocked_issue2, link_type: 'blocks') }
    let_it_be(:issue_link3) { create(:issue_link, source: blocking_issue3, target: blocked_issue2, link_type: 'blocks') }

    let(:query) do
      graphql_query_for('project', { fullPath: project.full_path }, query_graphql_field('issues', {}, issue_links_aggregates_query))
    end

    let(:single_issue_query) do
      graphql_query_for('project', { fullPath: project.full_path }, query_graphql_field('issues', { iid: blocked_issue1.iid.to_s }, issue_links_aggregates_query))
    end

    let(:issue_links_aggregates_query) do
      <<~QUERY
        nodes {
          id
          blocked
          blockedByCount
          blockedByIssues {
            nodes { id }
          }
        }
      QUERY
    end

    before do
      group.add_developer(current_user)
    end

    context 'working query' do
      before do
        post_graphql(single_issue_query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'
    end

    it 'uses the LazyLinksAggregate service' do
      expect(::Gitlab::Graphql::Aggregations::Issues::LazyLinksAggregate).to receive(:new)

      post_graphql(single_issue_query, current_user: current_user)
    end

    context 'correct result' do
      before do
        post_graphql(query, current_user: current_user)
      end

      it 'returns the correct blocked count result', :aggregate_failures do
        expect_blocked_count(blocked_issue1, true, 1)
        expect_blocked_count(blocked_issue2, true, 2)
        expect_blocked_count(blocking_issue1, false, 0)
        expect_blocked_count(blocking_issue2, false, 0)
        expect_blocked_count(blocking_issue3, false, 0)
      end

      it 'returns the correct blocked issue detail result', :aggregate_failures do
        expect_blocking_issues(blocked_issue1, [blocking_issue1])
        expect_blocking_issues(blocked_issue2, [blocking_issue2, blocking_issue3])
        expect_blocking_issues(blocking_issue1, [])
        expect_blocking_issues(blocking_issue2, [])
        expect_blocking_issues(blocking_issue3, [])
        expect_blocking_issues(unrelated_issue, [])
      end
    end

    def expect_blocking_issues(issue, expected_blocking_issues)
      nodes = graphql_data.dig('project', 'issues', 'nodes')
      node = nodes.find { |r| r['id'] == issue.to_global_id.to_s }

      expect(node['blockedByIssues']['nodes']).to match_array expected_blocking_issues.map { |i| { "id" => i.to_global_id.to_s }}
    end

    def expect_blocked_count(issue, expected_blocked, expected_blocked_count)
      nodes = graphql_data.dig('project', 'issues', 'nodes')
      node = nodes.find { |r| r['id'] == issue.to_global_id.to_s }

      expect(node['blocked']).to eq expected_blocked
      expect(node['blockedByCount']).to eq expected_blocked_count
    end
  end
end
