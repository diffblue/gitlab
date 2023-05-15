# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(id).dashboards', feature_category: :product_analytics do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :with_product_analytics_dashboard) }

  let(:query) do
    fields = all_graphql_fields_for('ProductAnalyticsDashboard')

    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_nodes(:product_analytics_dashboards, fields)
    )
  end

  before do
    stub_licensed_features(product_analytics: true)
  end

  context 'when current user is a developer' do
    before do
      project.add_developer(user)
    end

    it 'returns dashboards' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :product_analytics_dashboards, :nodes, 0, :title)).to eq('Dashboard Example 1')
      expect(graphql_data_at(:project, :product_analytics_dashboards, :nodes, 0, :slug)).to eq('dashboard_example_1')
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(product_analytics_dashboards: false)
      end

      it 'returns nil' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(:project, :product_analytics_dashboards, :nodes)).to be_nil
      end
    end
  end

  context 'when current user is a guest' do
    before do
      project.add_guest(user)
    end

    it 'returns no dashboards' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :product_analytics_dashboards, :nodes)).to be_nil
    end
  end
end
