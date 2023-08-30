# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Loading usage overvierw for a group', feature_category: :value_stream_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user).tap { |u| group.add_developer(u) } }
  let_it_be(:metric) do
    create(:value_stream_dashboard_count, metric: :projects, count: 5, namespace: group, recorded_at: '2023-01-20')
  end

  let(:params) do
    {
      identifier: :PROJECTS,
      timeframe: {
        start: '2023-01-01',
        end: '2023-01-31'
      }
    }
  end

  def query
    fields = %i[count]
    graphql_query_for("group", { "fullPath" => group.full_path },
      query_graphql_field("valueStreamDashboardUsageOverview", params, fields)
    )
  end

  context 'when the feature is available' do
    before do
      stub_licensed_features(group_level_analytics_dashboard: true)
    end

    it 'does return the count' do
      post_graphql(query, current_user: user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_data.dig('group', 'valueStreamDashboardUsageOverview', 'count')).to eq(5)
    end
  end

  context 'when the feature is not available' do
    it 'returns nil response' do
      post_graphql(query, current_user: user)

      expect(graphql_data.dig('group', 'valueStreamDashboardUsageOverview')).to eq(nil)
    end
  end
end
