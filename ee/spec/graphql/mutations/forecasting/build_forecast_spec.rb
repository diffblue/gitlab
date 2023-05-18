# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Forecasting::BuildForecast, feature_category: :devops_reports do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:production) { create :environment, :production, project: project }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  describe '#ready?' do
    let(:context) { project }
    let(:horizon) { 30 }
    let(:type) { 'deployment_frequency' }

    shared_examples 'raises argument error' do |message|
      it 'raises error with correct message' do
        expect do
          mutation.ready?(context_id: context.to_gid, type: type, horizon: horizon)
        end.to raise_error(Gitlab::Graphql::Errors::ArgumentError, message)
      end
    end

    context 'when horizon argument is invalid' do
      let(:horizon) { 99999 }

      it_behaves_like 'raises argument error', 'Forecast horizon must be positive and 90 days at the most.'
    end

    context 'when context_id argument is invalid' do
      let(:context) { user }

      it_behaves_like 'raises argument error', 'Invalid context type. Project is expected.'
    end

    context 'when type argument is invalid' do
      let(:type) { 'foo' }

      it_behaves_like 'raises argument error', 'Unsupported forecast type.'
    end
  end

  describe '#resolve' do
    subject do
      mutation.resolve(context_id: project.to_gid, type: type, horizon: horizon)
    end

    let(:horizon) { 30 }
    let(:type) { 'deployment_frequency' }

    let(:model_mock) { instance_double('Analytics::Forecasting::HoltWinters', r2_score: model_score) }
    let(:model_forecast) { (1...horizon).to_a }
    let(:model_score) { 1 }
    let(:license_available) { true }
    let(:user_role) { :developer }

    before do
      allow(Analytics::Forecasting::HoltWintersOptimizer).to receive(:model_for).and_return(model_mock)
      allow(model_mock).to receive(:predict).with(horizon).and_return(model_forecast)

      project.add_member(user, user_role)
      stub_licensed_features(dora4_analytics: license_available)
    end

    context 'when the user can read dora4 analytics' do
      context 'when forecast is good enough' do
        let(:expected_forecast) do
          model_forecast.map.with_index { |v, i| [Date.today + 1 + i, v] }.to_h
        end

        it 'returns the forecast with values' do
          expect(subject[:forecast].status).to eq('ready')
          expect(subject[:forecast].values).to eq(expected_forecast)
        end
      end

      context 'when the forecast is weak' do
        let(:model_score) { Analytics::Forecasting::Forecast::MINIMAL_SCORE_THRESHOLD - 0.1 }

        it 'returns the forecast object without values' do
          expect(subject[:forecast].status).to eq('unavailable')
          expect(subject[:forecast].values).to eq([])
        end
      end
    end

    context "when the user can't read dora4 analytics" do
      let(:user_role) { :guest }

      it 'denies access' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when context project has no proper license' do
      let(:license_available) { false }

      it 'denies access' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
