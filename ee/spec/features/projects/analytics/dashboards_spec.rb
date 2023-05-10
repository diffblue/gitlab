# frozen_string_literal: true

require 'spec_helper'
require_relative '../product_analytics/dashboards_shared_examples'

RSpec.describe 'Analytics Dashboard', :js, feature_category: :product_analytics do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:project) { create(:project, :repository) }

  before do
    sign_in(user)
    project.reload
  end

  subject(:visit_page) { visit project_analytics_dashboards_path(project) }

  shared_examples 'renders not found' do
    before do
      visit_page
    end

    it do
      expect(page).to have_content(s_('404|Page Not Found'))
    end
  end

  context 'with the combined dashboards feature flag disabled' do
    before do
      stub_feature_flags(combined_analytics_dashboards: false)
    end

    it_behaves_like 'renders not found'
  end

  context 'with the combined dashboards feature flag enabled' do
    before do
      stub_feature_flags(combined_analytics_dashboards: true)
    end

    context 'with the licensed feature disabled' do
      before do
        stub_licensed_features(combined_project_analytics_dashboards: false)
      end

      it_behaves_like 'renders not found'
    end

    context 'with the licensed feature enabled' do
      before do
        stub_licensed_features(combined_project_analytics_dashboards: true)
      end

      context 'without access to the project' do
        it_behaves_like 'renders not found'
      end

      context 'with access to the project' do
        before do
          project.add_guest(user)
        end

        context 'when loading the default page' do
          before do
            visit_page
          end

          it 'renders the dashboards list' do
            expect(page).to have_content('Analytics dashboards')
          end
        end

        it_behaves_like 'product analytics dashboards'
      end
    end

    context 'with the licensed feature enabled but snowplow disabled' do
      before do
        stub_licensed_features(combined_project_analytics_dashboards: true)
        stub_feature_flags(product_analytics_snowplow_support: false)
      end

      context 'without access to the project' do
        it_behaves_like 'renders not found'
      end

      context 'with access to the project' do
        before do
          project.add_guest(user)
        end

        it_behaves_like 'product analytics dashboards'
      end
    end
  end
end
