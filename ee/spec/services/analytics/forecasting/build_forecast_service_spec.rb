# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::Forecasting::BuildForecastService, feature_category: :devops_reports do
  let_it_be(:project) { create :project }
  let_it_be(:production) { create :environment, project: project }

  let(:type) { 'deployment_frequency' }
  let(:horizon) { 30 }
  let(:forecast_context) { project }

  subject(:service) { described_class.new(type: type, context: forecast_context, horizon: horizon) }

  describe '.validate' do
    subject { described_class.validate(type: type, context_class: forecast_context.class, horizon: horizon) }

    shared_examples_for 'forecast error' do |message|
      it 'returns error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq(message)
        expect(subject[:http_status]).to eq(:bad_request)
      end
    end

    context 'when forecast type is not supported' do
      let(:type) { 'something-invalid' }

      it_behaves_like 'forecast error', "Unsupported forecast type."
    end

    context 'when horizon is too big' do
      let(:horizon) { 91 }

      it_behaves_like 'forecast error', "Forecast horizon must be positive and 90 days at the most."
    end

    context 'when horizon is negative' do
      let(:horizon) { -1 }

      it_behaves_like 'forecast error', "Forecast horizon must be positive and 90 days at the most."
    end

    context 'when context is not a project' do
      let(:forecast_context) { User.new }

      it_behaves_like 'forecast error', "Invalid context type. Project is expected."
    end

    it 'returns no errors' do
      expect(subject).to eq nil
    end
  end

  describe '#execute' do
    subject { service.execute }

    it 'calls for validation and returns error' do
      expect(described_class).to receive(:validate).with(
        type: type,
        context_class: forecast_context.class,
        horizon: horizon).and_return(
          {
            message: 'error message',
            status: :error,
            http_status: :bad_request
          }
        )

      expect(subject[:status]).to eq(:error)
      expect(subject[:message]).to eq('error message')
      expect(subject[:http_status]).to eq(:bad_request)
    end

    it 'returns deployment frequency forecast for given horizon' do
      forecast_mock = instance_double('Analytics::Forecasting::DeploymentFrequencyForecast')

      expect(::Analytics::Forecasting::DeploymentFrequencyForecast).to receive(:new).and_return(forecast_mock)

      expect(subject[:status]).to eq(:success)
      expect(subject[:forecast]).to eq(forecast_mock)
    end
  end
end
