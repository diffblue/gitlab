# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Reports::Metrics::Report do
  let(:report) { described_class.new }

  describe '#add_metric' do
    let(:key) { 'metric_name' }
    let(:value) { 'metric_value' }

    subject { report.add_metric(key, value) }

    it 'stores given metric' do
      subject

      expect(report.metrics.count).to eq(1)
    end

    it 'correctly stores metric params' do
      subject

      expect(report.metrics[key]).to eq(value)
    end
  end
end
