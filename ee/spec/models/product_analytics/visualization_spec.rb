# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::Visualization, feature_category: :product_analytics do
  let_it_be(:project) do
    create(:project, :with_product_analytics_dashboard,
      project_setting: build(:project_setting, product_analytics_instrumentation_key: 'test')
    )
  end

  let(:dashboards) { project.product_analytics_dashboards }

  before do
    stub_licensed_features(product_analytics: true)
  end

  shared_examples_for 'a valid visualization' do
    it 'returns a valid visualization' do
      expect(dashboard.panels.first.visualization).to be_a(described_class)
    end
  end

  context 'when dashboard is a built-in dashboard' do
    let(:dashboard) { dashboards.find { |d| d.title == 'Audience' } }

    it_behaves_like 'a valid visualization'
  end

  context 'when dashboard is a local dashboard' do
    let(:dashboard) { dashboards.find { |d| d.title == 'Dashboard Example 1' } }

    it_behaves_like 'a valid visualization'
  end
end
