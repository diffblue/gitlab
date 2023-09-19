# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::Visualization, feature_category: :product_analytics_visualization do
  let_it_be(:project, reload: true) do
    create(:project, :with_product_analytics_dashboard,
      project_setting: build(:project_setting, product_analytics_instrumentation_key: 'test')
    )
  end

  let(:dashboards) { project.product_analytics_dashboards }
  let(:num_builtin_visualizations) { 15 }

  before do
    stub_licensed_features(
      product_analytics: true,
      project_level_analytics_dashboard: true,
      group_level_analytics_dashboard: true
    )
  end

  shared_examples_for 'a valid visualization' do
    it 'returns a valid visualization' do
      expect(dashboard.panels.first.visualization).to be_a(described_class)
    end
  end

  describe '#slug' do
    subject { described_class.for(container: project) }

    it 'returns the slugs' do
      expect(subject.map(&:slug)).to include('cube_bar_chart', 'cube_line_chart')
    end
  end

  describe '.for' do
    context 'when resource_parent is a Project' do
      subject { described_class.for(container: project) }

      it 'returns all visualizations stored in the project as well as built-in ones' do
        num_custom_visualizations = 2
        expect(subject.count).to eq(num_builtin_visualizations + num_custom_visualizations)
        expect(subject.map { |v| v.config['type'] }).to include('BarChart', 'LineChart')
      end

      context 'when a custom dashboard pointer project is configured' do
        let_it_be(:pointer_project) do
          create(:project, :with_product_analytics_custom_visualization, namespace: project.namespace)
        end

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

    context 'when resource_parent is a group' do
      let_it_be_with_reload(:group) { create(:group) }

      subject { described_class.for(container: group) }

      it 'returns built in visualizations' do
        expected_visualizations =
          ProductAnalytics::Visualization::PRODUCT_ANALYTICS_VISUALIZATIONS +
          ProductAnalytics::Visualization::VALUE_STREAM_DASHBOARD_VISUALIZATIONS

        expect(subject.map(&:slug)).to match_array(expected_visualizations)
      end

      context 'when group value stream dashboard is not available' do
        before do
          stub_licensed_features(group_level_analytics_dashboard: false)
        end

        it 'does not include built in visualizations for VSD' do
          expect(subject.map(&:slug)).to match_array(
            ProductAnalytics::Visualization::PRODUCT_ANALYTICS_VISUALIZATIONS
          )
        end
      end

      context 'when a custom configuration project is defined' do
        let_it_be(:config_project) { create(:project, :with_product_analytics_custom_visualization, group: group) }

        before do
          group.update!(analytics_dashboards_configuration_project: config_project)
        end

        it 'returns builtin and custom visualizations' do
          expected_visualizations =
            ProductAnalytics::Visualization::PRODUCT_ANALYTICS_VISUALIZATIONS +
            ProductAnalytics::Visualization::VALUE_STREAM_DASHBOARD_VISUALIZATIONS
          expected_visualizations.push('example_custom_visualization')

          expect(subject.map(&:slug)).to match_array(expected_visualizations)
        end
      end
    end
  end

  describe '.load_visualization_data' do
    context "when file exists" do
      subject do
        described_class.load_visualization_data("ee/lib/gitlab/analytics/product_analytics/visualizations",
          "total_sessions")
      end

      it "initializes visualization from file" do
        expect(subject.slug).to eq("total_sessions")
        expect(subject.errors).to be_nil
      end
    end

    context 'when file cannot be opened' do
      subject { described_class.load_visualization_data("ee/lib", "not-existing-file") }

      it 'initializes visualization with errors' do
        expect(subject.slug).to eq('not_existing_file')
        expect(subject.errors).to match_array(["Visualization file not-existing-file.yaml not found"])
      end
    end
  end

  describe '.load_value_stream_dashboard_visualization' do
    subject { described_class.load_value_stream_dashboard_visualization('dora_chart') }

    it 'returns the value stream dashboard builtin visualization' do
      expect(subject.slug).to eq('dora_chart')
    end
  end

  describe '.product_analytics_visualizations' do
    subject { described_class.product_analytics_visualizations }

    num_builtin_visualizations = 14

    it 'returns the product analytics builtin visualizations' do
      expect(subject.count).to eq(num_builtin_visualizations)
    end
  end

  describe '.value_stream_dashboard_visualizations' do
    subject { described_class.value_stream_dashboard_visualizations }

    num_builtin_visualizations = 1

    it 'returns the value stream dashboard builtin visualizations' do
      expect(subject.count).to eq(num_builtin_visualizations)
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

  context 'when visualization definition is invalid' do
    let_it_be(:project) do
      create(:project, :with_product_analytics_invalid_custom_visualization,
        project_setting: build(:project_setting, product_analytics_instrumentation_key: 'test')
      )
    end

    subject { described_class.for(container: project) }

    it 'captures the error' do
      vis = (subject.select { |v| v.slug == 'example_invalid_custom_visualization' }).first
      expected = ["property '/type' is not one of: " \
                  "[\"LineChart\", \"ColumnChart\", \"DataTable\", \"SingleStat\", \"DORAChart\"]"]
      expect(vis&.errors).to match_array(expected)
    end
  end

  context 'when the visualization has syntax errors' do
    let_it_be(:invalid_yaml) do
      <<-YAML
---
invalid yaml here not good
other: okay1111
      YAML
    end

    subject { described_class.new(config: invalid_yaml, slug: 'test') }

    it 'captures the syntax error' do
      expect(subject.errors).to match_array(['root is not of type: object'])
    end
  end

  context 'when initialized with init_error' do
    subject do
      described_class.new(config: nil, slug: "not-existing",
        init_error: "Some init error")
    end

    it 'captures the init_error' do
      expect(subject.errors).to match_array(['Some init error'])
    end
  end
end
