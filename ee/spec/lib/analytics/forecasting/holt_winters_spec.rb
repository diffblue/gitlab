# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::Forecasting::HoltWinters, feature_category: :devops_reports do
  subject { described_class.new(time_series, alpha: 0.5, beta: 0.5, gamma: 0.5, season: 7) }

  let(:time_series) do
    [
      0, 3, 4, 5, 4, 3, 0,
      0, 4, 5, 6, 5, 4, 0,
      1, 6, 7, 8, 7, 6, 1
    ]
  end

  # This forecast was manually calculated based on given time series and smoothing params.
  let(:expected_regression_values) do
    [
      nil, nil, nil, nil, nil, nil, nil,
      within(0.001).of(0.102),
      within(0.001).of(3.127),
      within(0.001).of(4.858),
      within(0.001).of(6.259),
      within(0.001).of(5.394),
      within(0.001).of(4.363),
      within(0.001).of(1.257),
      within(0.001).of(0.339),
      within(0.001).of(4.083),
      within(0.001).of(6.081),
      within(0.001).of(7.975),
      within(0.001).of(7.561),
      within(0.001).of(6.797),
      within(0.001).of(3.253)
    ]
  end

  let(:expected_forecast_values) do
    [
      within(0.001).of(2.773),
      within(0.001).of(6.626),
      within(0.001).of(6.500),
      within(0.001).of(6.591),
      within(0.001).of(4.969),
      within(0.001).of(3.604),
      within(0.001).of(-0.831)
    ]
  end

  describe '#validations' do
    context 'when there is less than 2 seasons of data' do
      let(:time_series) do
        [
          0, 3, 4, 5, 4, 3, 0
        ]
      end

      it 'raises an exception' do
        expect { subject }.to raise_error(Analytics::Forecasting::HoltWinters::NotEnoughDataError)
      end
    end
  end

  describe '.r2_score' do
    subject { described_class.r2_score(real, forecast) }

    let(:forecast) { [1.5, 2.5, 3.5, 4.5, 5.5] }
    let(:real) { [2, 3, 4, 5, 6] }

    it "calculated based on common r2 formula" do
      expect(subject).to be_within(0.001).of(0.875)
    end

    context 'when forecast or real data includes nils' do
      let(:forecast) { [nil, 2.5, 3.5, 4.5, 5.5] }
      let(:real) { [2, 3, 4, 5, nil] }

      it 'excludes nils from r2 score calculation' do
        expect(subject).to be_within(0.001).of(0.625)
      end
    end

    context 'when data is flat line (SSR = 0)' do
      let(:real) { [1, 1, 1, 1, 1] }

      it { is_expected.to eq 1.0 }
    end
  end

  describe '#predict' do
    it 'returns forecast values' do
      expect(subject.predict(7)).to match(expected_forecast_values)
    end
  end

  describe '#r2_score' do
    it 'delegates to class method with real and regression values' do
      expect(described_class).to receive(:r2_score).with(time_series, expected_regression_values)

      subject.r2_score
    end
  end
end
