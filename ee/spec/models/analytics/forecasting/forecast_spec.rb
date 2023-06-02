# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::Forecasting::Forecast, feature_category: :devops_reports do
  let(:model_score) { 0.4 }
  let(:model_mock) do
    instance_double('Analytics::Forecasting::HoltWinters', r2_score: model_score)
  end

  let(:forecast_type) { 'deployment_frequency' }
  let(:forecast_horizon) { 30 }
  let(:forecast_context) { Project.new }

  before do
    allow(Analytics::Forecasting::HoltWintersOptimizer).to receive(:model_for).and_return(model_mock)
  end

  describe '.for' do
    it 'returns corresponding classes by type' do
      expect(described_class.for('deployment_frequency')).to eq(Analytics::Forecasting::DeploymentFrequencyForecast)
      expect(described_class.for('something_else')).to eq(nil)
    end
  end

  describe '.context_class' do
    it 'raises NoMethodError' do
      expect do
        described_class.context_class
      end.to raise_error NoMethodError, 'must be implemented in a subclass'
    end
  end

  subject do
    described_class.for(forecast_type).new(type: forecast_type, horizon: forecast_horizon, context: forecast_context)
  end

  describe '#status' do
    context 'when model score >= 0.4' do
      it 'returns "ready"' do
        expect(subject.status).to eq 'ready'
      end
    end

    context 'when model score < 0.4' do
      let(:model_score) { 0.39 }

      it 'returns "unavailable"' do
        expect(subject.status).to eq 'unavailable'
      end
    end
  end

  describe '#source_time_series' do
    it 'raises NoMethodError' do
      expect do
        described_class.new.source_time_series
      end.to raise_error NoMethodError, 'must be implemented in a subclass'
    end
  end

  describe '#values' do
    let(:model_forecast) { (1..forecast_horizon).to_a }

    before do
      allow(model_mock).to receive(:predict).with(forecast_horizon).and_return(model_forecast)
    end

    it 'returns forecast hash with dates and model forecast values', :freeze_time do
      expect(subject.values).to be_kind_of Hash
      expect(subject.values.values).to eq(model_forecast)
      expect(subject.values.keys).to eq(((Date.today + 1)..(Date.today + forecast_horizon)).to_a)
    end
  end

  describe '#initialize' do
    context 'when context has wrong class' do
      let(:forecast_context) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error 'Invalid context class.'
      end
    end
  end
end
