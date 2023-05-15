# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::Forecasting::BuildForecastService, feature_category: :devops_reports do
  let_it_be(:project) { create :project }
  let_it_be(:production) { create :environment, project: project }

  let(:type) { 'deployment_frequency' }
  let(:horizon) { 30 }
  let(:forecast_context) { project }

  subject(:service) { described_class.new(type: type, context: forecast_context, horizon: horizon) }

  describe '#execute' do
    subject { service.execute }

    shared_examples_for 'failure response' do |message|
      it 'returns error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq(message)
        expect(subject[:http_status]).to eq(:bad_request)
      end
    end

    context 'when forecast type is not supported' do
      let(:type) { 'something-invalid' }

      it_behaves_like 'failure response', "Unsupported forecast type. Supported types: [\"deployment_frequency\"]"
    end

    context 'when horizon is too big' do
      let(:horizon) { 91 }

      it_behaves_like 'failure response', "Forecast horizon must be 90 days at the most."
    end

    context 'when context is not a project' do
      let(:forecast_context) { User.new }

      it_behaves_like 'failure response', "Invalid context. Project is expected."
    end

    it 'returns deployment frequency forecast for given horizon' do
      forecast_mock = instance_double('Analytics::Forecasting::DeploymentFrequencyForecast')

      expect(::Analytics::Forecasting::DeploymentFrequencyForecast).to receive(:new).and_return(forecast_mock)

      expect(subject[:status]).to eq(:success)
      expect(subject[:forecast]).to eq(forecast_mock)
    end
  end
end
