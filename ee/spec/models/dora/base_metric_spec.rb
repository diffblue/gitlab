# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dora::BaseMetric do
  describe '.all_metric_classes' do
    it 'returns list of 4 metric classes' do
      expect(described_class.all_metric_classes)
        .to match_array(
          [Dora::DeploymentFrequencyMetric,
           Dora::LeadTimeForChangesMetric,
           Dora::TimeToRestoreServiceMetric,
           Dora::ChangeFailureRateMetric]
        )
    end
  end

  describe '.for' do
    it 'returns metric class by its metric name' do
      described_class.all_metric_classes do |klass|
        expect(described_class.for(klass::METRIC_NAME)).to eq(klass)
      end
    end

    it 'raises error if there is no defined metric class' do
      expect { described_class.for('this-is-not-a-metric-key') }.to raise_error(ArgumentError, 'Unknown metric')
    end
  end

  describe '#data_queries' do
    subject do
      Object.new.tap do |obj|
        obj.extend described_class
      end
    end

    it 'raises a requirement to overload the method' do
      expect { subject.data_queries }.to raise_error(NoMethodError, "method `data_queries` must be overloaded for #{subject.class.name}")
    end
  end
end
