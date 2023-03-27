# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::DoraMetricsAggregator, feature_category: :devops_reports do
  describe '.aggregate_for' do
    let_it_be(:project) { create(:project) }
    let(:metric) { 'deployment_frequency' }
    let(:end_date) { Time.current.to_date }
    let(:start_date) { 3.months.ago(end_date) }
    let(:params) do
      {
        projects: [project],
        start_date: start_date,
        end_date: end_date,
        metrics: [metric],
        environment_tiers: ['production'],
        interval: Dora::DailyMetrics::INTERVAL_DAILY
      }.merge(extra_params)
    end

    let(:extra_params) { {} }
    let_it_be(:production) { create(:environment, :production, project: project) }
    let_it_be(:staging) { create(:environment, :staging, project: project) }

    subject { described_class.aggregate_for(**params) }

    around do |example|
      freeze_time do
        example.run
      end
    end

    before_all do
      create(:dora_daily_metrics, deployment_frequency: 2, environment: production)
      create(:dora_daily_metrics, deployment_frequency: 1, environment: staging)
    end

    before do
      stub_licensed_features(dora4_analytics: true)
    end

    it 'returns the aggregated data' do
      expect(subject).to match_array([{ 'date' => Time.current.to_date.to_s, metric => 2 }])
    end

    context 'when interval is monthly' do
      let(:extra_params) { { interval: Dora::DailyMetrics::INTERVAL_MONTHLY } }

      it 'returns the aggregated data' do
        expect(subject).to match_array([{ 'date' => Time.current.beginning_of_month.to_date.to_s, metric => 2 }])
      end
    end

    context 'when interval is all' do
      let(:extra_params) { { interval: Dora::DailyMetrics::INTERVAL_ALL } }

      it 'returns the aggregated data' do
        expect(subject).to match_array([{ 'date' => nil, metric => 2 }])
      end
    end

    context 'when environment tiers are changed' do
      let(:extra_params) { { environment_tiers: ['staging'] } }

      it 'returns the aggregated data' do
        expect(subject).to match_array([{ 'date' => Time.current.to_date.to_s, metric => 1 }])
      end
    end
  end
end
