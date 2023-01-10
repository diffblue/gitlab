# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group.contributions', feature_category: :value_stream_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group).tap { |g| g.add_developer(user) } }
  let_it_be(:project) { create(:project, group: group) }

  let(:query) do
    <<~QUERY
    query($fullPath: ID!) {
      group(fullPath: $fullPath) {
        contributions(from: "2022-01-01", to: "2022-01-10") {
          nodes {
            user {
              id
            }
            totalEvents
            repoPushed
          }
        }
      }
    }
    QUERY
  end

  context 'when the license is not available' do
    it 'returns no data' do
      stub_licensed_features(contribution_analytics: false)

      post_graphql(query, current_user: user, variables: { fullPath: group.full_path })

      expect(graphql_data).to eq({ 'group' => { 'contributions' => nil } })
    end
  end

  context 'when the license is available' do
    before do
      stub_licensed_features(contribution_analytics: true)
      create(:event, :pushed, project: project, author: user, created_at: Date.parse('2022-01-05'))
    end

    it 'returns data' do
      post_graphql(query, current_user: user, variables: { fullPath: group.full_path })

      expect(graphql_data_at('group', 'contributions', 'nodes')).to eq([
        { 'user' => { 'id' => user.to_gid.to_s },
          'totalEvents' => 1,
          'repoPushed' => 1 }
      ])
    end

    context 'with events from different users' do
      def run_query
        post_graphql(query, current_user: user, variables: { fullPath: group.full_path })
      end

      it 'does not create N+1 queries' do
        # warm the query to avoid flakiness
        run_query

        control_count = ActiveRecord::QueryRecorder.new { run_query }

        create(:event, :pushed, project: project, author: create(:user), created_at: Date.parse('2022-01-05'))
        expect { run_query }.not_to exceed_all_query_limit(control_count)
      end
    end
  end
end
