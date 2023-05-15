# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::Forecasting::HoltWintersOptimizer, feature_category: :devops_reports do
  subject { described_class.new(time_series, model_class: model_mock) }

  let(:time_series) do
    [
      0, 3, 4, 5, 4, 3, 0,
      0, 4, 5, 6, 5, 4, 0,
      1, 6, 7, 8, 7, 6, 1
    ]
  end

  let(:model_mock) do
    Class.new do
      attr_reader :alpha, :beta, :gamma

      def initialize(_time_series, alpha:, beta:, gamma:, **_params)
        @alpha = alpha.to_f
        @beta = beta.to_f
        @gamma = gamma.to_f
      end

      # Mock R2 score calculation so it has best fit at our expected best_params
      def r2_score
        f_alpha = 1 - (@alpha - 0.2).abs
        f_beta = 1 - (@beta - 0.7).abs
        f_gamma = 1 - (@gamma - 0.36).abs

        f_alpha * f_beta * f_gamma
      end
    end
  end

  let(:best_params) do
    {
      alpha: 0.2,
      beta: 0.7,
      gamma: 0.36
    }
  end

  describe '#model' do
    it 'returns model close to best fit params' do
      model = subject.model

      expect(model.alpha).to be_within(0.05).of(best_params[:alpha])
      expect(model.beta).to be_within(0.05).of(best_params[:beta])
      expect(model.gamma).to be_within(0.05).of(best_params[:gamma])
    end
  end

  describe '.model_for' do
    it 'returns best fit model' do
      model = described_class.model_for(time_series, model_class: model_mock)

      expect(model.alpha).to be_within(0.05).of(best_params[:alpha])
      expect(model.beta).to be_within(0.05).of(best_params[:beta])
      expect(model.gamma).to be_within(0.05).of(best_params[:gamma])
    end
  end
end
