# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProductAnalytics::Dashboard, feature_category: :product_analytics do
  let_it_be(:project) do
    create(:project, :with_product_analytics_dashboard,
      project_setting: build(:project_setting, product_analytics_instrumentation_key: 'test')
    )
  end

  before do
    stub_feature_flags(product_analytics_snowplow_support: false)
    stub_licensed_features(product_analytics: true)
  end

  describe '.for_project' do
    subject { described_class.for_project(project) }

    it 'returns a collection of dashboards' do
      expect(subject).to be_a(Array)
      expect(subject.size).to eq(1)
      expect(subject.first).to be_a(described_class)
      expect(subject.first.title).to eq('Dashboard Example 1')
      expect(subject.first.slug).to eq('dashboard_example_1')
      expect(subject.first.description).to eq('North Star Metrics across all departments for the last 3 quarters.')
      expect(subject.first.schema_version).to eq('1')
    end

    it 'does not include hardcoded dashboards' do
      expect(subject.map(&:title)).not_to include('Audience', 'Behavior')
    end

    context 'when the snowplow feature flag is enabled' do
      before do
        stub_feature_flags(product_analytics_snowplow_support: true)
      end

      it 'includes hardcoded dashboards' do
        expect(subject.size).to eq(3)
        expect(subject.map(&:title)).to include('Audience', 'Behavior')
      end
    end

    context 'when the project does not have a dashboards directory' do
      let_it_be(:project) { create(:project, :repository) }

      it { is_expected.to be_empty }
    end

    context 'when the dashboard file does not exist in the directory' do
      before do
        project.repository.create_file(
          project.creator,
          '.gitlab/analytics/dashboards/dashboard_example_1/dashboard_example_wrongly_named.yaml',
          File.open(Rails.root.join('ee/spec/fixtures/product_analytics/dashboard_example_1.yaml')).read,
          message: 'test',
          branch_name: 'master'
        )
      end

      it 'excludes the dashboard from the list' do
        expect(subject.size).to eq(1)
      end
    end

    context 'when the project does not have a dashboard directory' do
      let_it_be(:project) { create(:project) }

      it 'returns an empty array' do
        expect(subject).to be_empty
      end
    end
  end

  describe '#panels' do
    subject { described_class.for_project(project).first.panels }

    it { is_expected.to be_a(Array) }

    it 'is expected to contain two panels' do
      expect(subject.size).to eq(2)
    end

    it 'is expected to contain a panel with the correct title' do
      expect(subject.first.title).to eq('Overall Conversion Rate')
    end

    it 'is expected to contain a panel with the correct grid attributes' do
      expect(subject.first.grid_attributes).to eq({ 'xPos' => 1, 'yPos' => 4, 'width' => 12, 'height' => 2 })
    end
  end

  describe '#==' do
    let(:dashboard_1) { described_class.for_project(project).first }
    let(:dashboard_2) do
      described_class.new(title: 'a', description: 'b', schema_version: '1', panels: [], project: nil, slug: 'test2')
    end

    subject { dashboard_1 == dashboard_2 }

    it { is_expected.to be false }
  end
end
