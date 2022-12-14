# frozen_string_literal: true
require 'spec_helper'

RSpec.describe 'getting Issue counts by status', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:iteration) { create(:iteration, group: group) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:project) { create(:project, :repository, group: group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:issue_opened1) { create(:issue, project: project, weight: 3, epic: epic) }
  let_it_be(:issue_opened2) { create(:issue, project: project, iteration: iteration) }
  let_it_be(:issue_closed) { create(:issue, :closed, project: project) }
  let_it_be(:other_project_issue) { create(:issue) }

  let(:params) { {} }

  let(:fields) do
    <<~QUERY
      #{all_graphql_fields_for('IssueStatusCountsType'.classify)}
    QUERY
  end

  let(:query) do
    graphql_query_for(
      'project',
      { 'fullPath' => project.full_path },
      query_graphql_field('issueStatusCounts', params, fields)
    )
  end

  context 'with issue count data' do
    let(:issue_counts) { graphql_data.dig('project', 'issueStatusCounts') }

    context 'with project permissions' do
      before do
        project.add_developer(current_user)
        post_graphql(query, current_user: current_user)
      end

      it_behaves_like 'a working graphql query'

      it 'returns the correct counts for each status' do
        expect(issue_counts).to eq(
          'all' => 3,
          'opened' => 2,
          'closed' => 1
        )
      end

      context 'when filters are provided' do
        context 'when filtering by weight' do
          let(:params) { { 'weight' => '3' } }

          it 'returns the correct counts for each status' do
            expect(issue_counts).to eq(
              'all' => 1,
              'opened' => 1,
              'closed' => 0
            )
          end
        end

        context 'when filtering by iteration' do
          let(:params) { { 'iterationId' => iteration.to_gid.to_s } }

          it 'returns the correct counts for each status' do
            expect(issue_counts).to eq(
              'all' => 1,
              'opened' => 1,
              'closed' => 0
            )
          end
        end

        context 'when filtering by epic' do
          let(:params) { { 'epicId' => epic.id.to_s, 'includeSubepics' => true } }

          it 'returns the correct counts for each status' do
            expect(issue_counts).to eq(
              'all' => 1,
              'opened' => 1,
              'closed' => 0
            )
          end
        end

        context 'when filtering by health status' do
          let(:params) { { 'healthStatusFilter' => :ANY } }

          it 'returns the correct counts for each status' do
            expect(issue_counts).to eq(
              'all' => 0,
              'opened' => 0,
              'closed' => 0
            )
          end
        end
      end
    end
  end
end
