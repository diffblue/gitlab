# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CompareMetricsReportsService, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project, :repository) }

  let(:service) { described_class.new(project) }

  before do
    stub_licensed_features(metrics_reports: true)
  end

  describe '#execute' do
    subject { service.execute(base_pipeline, head_pipeline) }

    context 'when head pipeline has metrics reports' do
      let!(:base_pipeline) { nil }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_metrics_report, project: project) }

      it 'reports new metrics' do
        expect(subject[:status]).to eq(:parsed)
        expect(subject[:data]['new_metrics'].count).to eq(2)
      end
    end

    context 'when base and head pipelines have metrics reports' do
      let!(:base_pipeline) { create(:ee_ci_pipeline, :with_metrics_report, project: project) }
      let!(:head_pipeline) { create(:ee_ci_pipeline, :with_metrics_alternate_report, project: project) }

      it 'reports status as parsed' do
        expect(subject[:status]).to eq(:parsed)
      end

      it 'reports new licenses' do
        expect(subject[:data]['new_metrics'].count).to eq(1)
        expect(subject[:data]['new_metrics']).to include(a_hash_including('name' => 'third_metric'))
      end

      it 'reports existing metrics' do
        expect(subject[:data]['existing_metrics'].count).to eq(1)
        expect(subject[:data]['existing_metrics']).to include(a_hash_including('name' => 'first_metric'))
      end

      it 'reports removed metrics' do
        expect(subject[:data]['removed_metrics'].count).to eq(1)
        expect(subject[:data]['removed_metrics']).to include(a_hash_including('name' => 'second_metric'))
      end
    end
  end
end
