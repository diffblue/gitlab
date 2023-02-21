# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Analytics Dashboard', :js, feature_category: :product_analytics do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:query_response_with_unknown_error) { fixture_file('cube_js/query_with_error.json', dir: 'ee') }
  let_it_be(:query_response_with_no_db_error) { fixture_file('cube_js/query_with_no_db_error.json', dir: 'ee') }
  let_it_be(:query_response_with_data) { fixture_file('cube_js/query_with_data.json', dir: 'ee') }

  let(:cube_api_url) { "https://cube.example.com/cubejs-api/v1/load" }

  before do
    stub_feature_flags(cube_api_proxy: true)
    project.add_guest(user)
    project.project_setting.update!(jitsu_key: '123')
    project.reload
    sign_in(user)
  end

  subject(:visit_page) { visit project_analytics_dashboards_path(project) }

  shared_examples 'does not render the product analytics dashboards' do
    before do
      visit_page
    end

    it do
      expect(page).not_to have_content('Understand your audience')
    end
  end

  context 'when loading the default page' do
    before do
      visit_page
    end

    it 'renders the dashboards list' do
      expect(page).to have_content('Analytics dashboards')
    end

    it_behaves_like 'does not render the product analytics dashboards'
  end
end
