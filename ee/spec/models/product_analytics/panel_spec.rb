# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::Panel, feature_category: :product_analytics do
  let_it_be(:project) { create(:project, :with_product_analytics_dashboard) }

  subject { project.product_analytics_dashboard('dashboard_example_1').panels.first.visualization }

  before do
    stub_licensed_features(product_analytics: true)
    stub_feature_flags(product_analytics_dashboards: true)
  end

  it 'returns the correct object' do
    expect(subject.type).to eq('LineChart')
    expect(subject.options)
      .to eq({ 'xAxis' => { 'name' => 'Time', 'type' => 'time' }, 'yAxis' => { 'name' => 'Counts' } })
    expect(subject.data['type']).to eq('Cube')
  end
end
