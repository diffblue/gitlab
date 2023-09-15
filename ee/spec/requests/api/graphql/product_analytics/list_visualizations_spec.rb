# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.resource_parent(id).visualizations', feature_category: :product_analytics_visualization do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }

  let(:query) do
    <<~GRAPHQL
      query {
        #{resource_parent_type}(fullPath: "#{resource_parent.full_path}") {
          name
          customizableDashboardVisualizations {
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
        #{resource_parent_type}(fullPath: "#{resource_parent.full_path}") {
          name
          customizableDashboardVisualizations(slug: "cube_bar_chart") {
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

  shared_examples 'listing visualizations' do
    context 'when user has developer access' do
      before do
        resource_parent.add_developer(user)
      end

      context 'when querying a specific visualization' do
        let(:query) { single_query }

        it 'returns the specific visualization', :aggregate_failures do
          get_graphql(query, current_user: user)

          expect(
            graphql_data_at(resource_parent_type, :customizable_dashboard_visualizations, :nodes).count
          ).to eq(1)
          expect(
            graphql_data_at(resource_parent_type, :customizable_dashboard_visualizations, :nodes, 0, :type)
          ).to eq('BarChart')
          expect(
            graphql_data_at(resource_parent_type, :customizable_dashboard_visualizations, :nodes, 0, :slug)
          ).to eq('cube_bar_chart')
        end
      end

      it 'returns visualizations', :aggregate_failures do
        get_graphql(query, current_user: user)

        expect(
          graphql_data_at(resource_parent_type, :customizable_dashboard_visualizations, :nodes, 0, :type)
        ).to eq('BarChart')
        expect(
          graphql_data_at(resource_parent_type, :customizable_dashboard_visualizations, :nodes, 0, :slug)
        ).to eq('cube_bar_chart')
        expect(
          graphql_data_at(resource_parent_type, :customizable_dashboard_visualizations, :nodes, 1, :type)
        ).to eq('LineChart')
        expect(
          graphql_data_at(resource_parent_type, :customizable_dashboard_visualizations, :nodes, 1, :slug)
        ).to eq('cube_line_chart')
      end
    end

    context 'when user has guest access' do
      before do
        resource_parent.add_guest(user)
      end

      it 'returns nil', :aggregate_failures do
        get_graphql(query, current_user: user)

        expect(graphql_data_at(resource_parent_type, :customizable_dashboard_visualizations)).to be_nil
      end
    end

    context 'when user is not authenticated' do
      it 'returns nil', :aggregate_failures do
        get_graphql(query, current_user: nil)

        expect(graphql_data_at(resource_parent_type, :customizable_dashboard_visualizations)).to be_nil
      end
    end
  end

  context 'when resource parent is a project' do
    let_it_be(:resource_parent) { create(:project, :with_product_analytics_dashboard) }

    let(:resource_parent_type) { :project }

    it_behaves_like 'listing visualizations'
  end

  context 'when resource parent is a group' do
    let_it_be(:resource_parent) { create(:group) }
    let_it_be(:config_project) { create(:project, :with_product_analytics_dashboard, group: resource_parent) }

    let(:resource_parent_type) { :group }

    before_all do
      resource_parent.update!(analytics_dashboards_configuration_project: config_project)
    end

    it_behaves_like 'listing visualizations'
  end
end
