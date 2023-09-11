# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(id).dashboards', feature_category: :product_analytics_data_management do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :with_product_analytics_dashboard) }

  let(:query) do
    fields = all_graphql_fields_for('CustomizableDashboard')

    graphql_query_for(
      :project,
      { full_path: project.full_path },
      query_nodes(:customizable_dashboards, fields)
    )
  end

  before do
    stub_licensed_features(product_analytics: true, project_level_analytics_dashboard: true)

    project.project_setting.update!(product_analytics_instrumentation_key: 'test-key')
    project.reload
  end

  context 'when current user is a developer' do
    before do
      project.add_developer(user)
    end

    it 'returns dashboards' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :customizable_dashboards, :nodes, 3, :title)).to eq('Dashboard Example 1')
      expect(graphql_data_at(:project, :customizable_dashboards, :nodes, 3, :slug)).to eq('dashboard_example_1')
    end

    it 'returns three gitlab provided dashboards' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :customizable_dashboards, :nodes).pluck('userDefined'))
        .to match_array([false, false, false, true])
    end

    context 'when feature flag is disabled' do
      before do
        stub_feature_flags(product_analytics_dashboards: false)
      end

      it 'returns nil' do
        post_graphql(query, current_user: user)

        expect(graphql_data_at(:project, :customizable_dashboards, :nodes)).to be_nil
      end
    end
  end

  context 'when current user is a guest' do
    before do
      project.add_guest(user)
    end

    it 'returns no dashboards' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :customizable_dashboards, :nodes)).to be_nil
    end
  end

  context 'without the project_level_analytics_dashboard license' do
    before do
      stub_licensed_features(product_analytics: true, project_level_analytics_dashboard: false)

      project.add_developer(user)
    end

    it 'does not return the Value stream dashboard' do
      post_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :customizable_dashboards, :nodes).pluck('slug'))
        .not_to include('value_stream_dashboard')
    end
  end
end
