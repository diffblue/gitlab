# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::Visualization, feature_category: :product_analytics_visualization do
  let_it_be(:project, reload: true) do
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

  describe '#slug' do
    subject { described_class.for_project(project) }

    it 'returns the slugs' do
      expect(subject.map(&:slug)).to include('cube_bar_chart', 'cube_line_chart')
    end
  end

  describe '.for_project' do
    subject { described_class.for_project(project) }

    num_builtin_visualizations = 14

    it 'returns all visualizations stored in the project as well as built-in ones' do
      num_custom_visualizations = 2
      expect(subject.count).to eq(num_builtin_visualizations + num_custom_visualizations)
      expect(subject.map { |v| v.config['type'] }).to include('BarChart', 'LineChart')
    end

    context 'when a custom dashboard pointer project is configured' do
      let_it_be(:pointer_project) { create(:project, :with_product_analytics_custom_visualization) }

      before do
        project.update!(analytics_dashboards_configuration_project: pointer_project)
      end

      it 'returns custom visualizations from pointer project' do
        num_custom_visualizations = 1
        expect(subject.count).to eq(num_builtin_visualizations + num_custom_visualizations)
        expect(subject.map(&:slug)).to include('example_custom_visualization')
      end

      it 'does not return custom visualizations from self' do
        expect(subject.map { |v| v.config['title'] }).not_to include('Daily Something', 'Example title')
      end
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

  context 'when visualization is loaded with attempted path traversal' do
    let_it_be(:project) do
      create(:project, :with_dashboard_attempting_path_traversal,
        project_setting: build(:project_setting, product_analytics_instrumentation_key: 'test')
      )
    end

    let(:dashboard) { dashboards.find { |d| d.title == 'Dashboard Example 1' } }

    it 'raises an error' do
      expect { dashboard.panels.first.visualization }.to raise_error(Gitlab::PathTraversal::PathTraversalAttackError)
    end
  end
end
