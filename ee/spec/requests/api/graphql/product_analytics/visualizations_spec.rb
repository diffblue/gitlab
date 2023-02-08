# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(id).dashboards.panels(id).visualization', feature_category: :product_analytics do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :with_product_analytics_dashboard) }

  let(:query) do
    <<~GRAPHQL
      query {
        project(fullPath: "#{project.full_path}") {
          name
          productAnalyticsDashboards {
            nodes {
              title
              description
              panels {
                nodes {
                  title
                  gridAttributes
                  visualization {
                    type
                    options
                    data
                  }
                }
              }
            }
          }
        }
      }
    GRAPHQL
  end

  before do
    stub_licensed_features(product_analytics: true)
  end

  context 'when current user is a developer' do
    let_it_be(:user) { create(:user).tap { |u| project.add_developer(u) } }

    it 'returns visualization' do
      get_graphql(query, current_user: user)

      expect(
        graphql_data_at(:project, :product_analytics_dashboards, :nodes, 0, :panels, :nodes, 0, :visualization, :type)
      ).to eq('LineChart')
    end

    context 'when the visualization does not exist' do
      before do
        allow_next_instance_of(ProductAnalytics::Panel) do |panel|
          allow(panel).to receive(:visualization).and_return(nil)
        end
      end

      it 'returns an error' do
        get_graphql(query, current_user: user)

        expect(graphql_errors).to include(a_hash_including('message' => 'Visualization does not exist'))
      end
    end
  end
end
