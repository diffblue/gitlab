# frozen_string_literal: true

require 'spec_helper'
require_relative '../product_analytics/dashboards_shared_examples'

RSpec.describe 'Analytics Dashboard', :js, feature_category: :product_analytics_data_management do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:project) { create(:project, :repository) }

  before do
    sign_in(user)
    project.reload
  end

  subject(:visit_page) { visit project_analytics_dashboards_path(project) }

  it_behaves_like 'product analytics dashboards' do
    let(:project_settings) { { product_analytics_instrumentation_key: 456 } }
    let(:application_settings) do
      {
        product_analytics_configurator_connection_string: 'https://configurator.example.com',
        product_analytics_data_collector_host: 'https://collector.example.com',
        cube_api_base_url: 'https://cube.example.com',
        cube_api_key: '123'
      }
    end
  end
end
