# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::Widget do
  let_it_be(:project) { create(:project, :with_product_analytics_dashboard) }

  subject { project.product_analytics_dashboard('dashboard_example_1').widgets.first.visualization }

  before do
    stub_licensed_features(product_analytics: true)
    stub_feature_flags(cube_api_proxy: true)
  end

  it 'returns the correct object' do
    expect(subject.type).to eq('LineChart')
    expect(subject.options)
      .to eq({ 'xAxis' => { 'name' => 'Time', 'type' => 'time' }, 'yAxis' => { 'name' => 'Counts' } })
    expect(subject.data['type']).to eq('Cube')
  end
end
