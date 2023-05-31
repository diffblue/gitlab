# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::Forecasting::DeploymentFrequencyForecast, feature_category: :devops_reports do
  let(:model_score) { 0.4 }
  let(:model_mock) do
    instance_double('Analytics::Forecasting::HoltWinters', r2_score: model_score)
  end

  let(:forecast_type) { 'deployment_frequency' }
  let(:horizon) { 30 }
  let_it_be(:project) { create(:project) }
  let_it_be(:production_env) { create(:environment, :production, project: project) }
  let_it_be(:production_env_2) { create(:environment, :production, project: project, name: 'production_2') }

  subject { described_class.new(context: project, horizon: horizon, type: forecast_type) }

  around do |example|
    freeze_time { example.run }
  end

  before do
    allow(Analytics::Forecasting::HoltWintersOptimizer).to receive(:model_for).and_return(model_mock)
  end

  describe '.context_class' do
    it 'is Project' do
      expect(described_class.context_class).to eq Project
    end
  end

  describe '#source_time_series' do
    let(:daily_metrics) do
      [nil, 5, 6, 3, 4, nil, nil, 4, 5, 6, 4, 3]
    end

    let(:expected_metrics) do
      (1.year.ago.to_date..Date.today).map.with_index { |date, i| [date, daily_metrics[i] || 0] }.to_h
    end

    before do
      # Create dora metric records.
      daily_metrics.each.with_index do |value, i|
        next unless value

        create(:dora_daily_metrics,
          environment: i.odd? ? production_env : production_env_2,
          deployment_frequency: value,
          date: 1.year.ago.to_date + i)
      end
    end

    it 'returns deployment frequency metrics for last year with gaps filled' do
      expect(subject.source_time_series).to eq(expected_metrics)
    end
  end

  describe '#values' do
    let(:model_forecast) { [1.1, 2, 3.5, 3.9, -1.3] }
    let(:expected_forecast) do
      [1, 2, 4, 4, 0].map.with_index { |v, i| [Date.today + i + 1, v] }.to_h
    end

    before do
      allow(model_mock).to receive(:predict).with(horizon).and_return(model_forecast)
    end

    it 'returns rounded positive values of whatever model forecasts' do
      expect(subject.values).to eq expected_forecast
    end
  end
end
