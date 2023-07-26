# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(id).visualizations', feature_category: :product_analytics do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :with_product_analytics_dashboard) }

  let(:query) do
    <<~GRAPHQL
      query {
        project(fullPath: "#{project.full_path}") {
          name
          productAnalyticsVisualizations {
            nodes {
               type
               options
               data
               slug
            }
          }
        }
      }
    GRAPHQL
  end

  let(:single_query) do
    <<~GRAPHQL
      query {
        project(fullPath: "#{project.full_path}") {
          name
          productAnalyticsVisualizations(slug: "cube_bar_chart") {
            nodes {
               type
               options
               data
               slug
            }
          }
        }
      }
    GRAPHQL
  end

  before do
    stub_licensed_features(product_analytics: true)
  end

  context 'when user has developer access' do
    before do
      project.add_developer(user)
    end

    context 'when querying a specific visualization' do
      let(:query) { single_query }

      it 'returns the specific visualization', :aggregate_failures do
        get_graphql(query, current_user: user)

        expect(
          graphql_data_at(:project, :product_analytics_visualizations, :nodes).count
        ).to eq(1)
        expect(
          graphql_data_at(:project, :product_analytics_visualizations, :nodes, 0, :type)
        ).to eq('BarChart')
        expect(
          graphql_data_at(:project, :product_analytics_visualizations, :nodes, 0, :slug)
        ).to eq('cube_bar_chart')
      end
    end

    it 'returns visualizations', :aggregate_failures do
      get_graphql(query, current_user: user)

      expect(
        graphql_data_at(:project, :product_analytics_visualizations, :nodes, 0, :type)
      ).to eq('BarChart')
      expect(
        graphql_data_at(:project, :product_analytics_visualizations, :nodes, 0, :slug)
      ).to eq('cube_bar_chart')
      expect(
        graphql_data_at(:project, :product_analytics_visualizations, :nodes, 1, :type)
      ).to eq('LineChart')
      expect(
        graphql_data_at(:project, :product_analytics_visualizations, :nodes, 1, :slug)
      ).to eq('cube_line_chart')
    end
  end

  context 'when user has guest access' do
    before do
      project.add_guest(user)
    end

    it 'returns nil', :aggregate_failures do
      get_graphql(query, current_user: user)

      expect(graphql_data_at(:project, :product_analytics_visualizations)).to be_nil
    end
  end

  context 'when user is not authenticated' do
    it 'returns nil', :aggregate_failures do
      get_graphql(query, current_user: nil)

      expect(graphql_data_at(:project, :product_analytics_visualizations)).to be_nil
    end
  end
end
