# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Insights::Reducers::DoraReducer do
  context 'when metric=change_failure_rate' do
    it 'converts to percentage' do
      data = [
        { 'value' => 0.5, 'date' => '2020-01-01' },
        { 'value' => 0.1, 'date' => '2020-01-02' }
      ]

      result = described_class
        .reduce(data, period: 'day', metric: 'change_failure_rate')

      expect(result).to eq({ '01 Jan 20' => 50, '02 Jan 20' => 10 })
    end
  end

  context 'when metric=deployment_frequency' do
    it 'uses the value as is' do
      data = [
        { 'value' => 100, 'date' => '2020-01-01' },
        { 'value' => 20, 'date' => '2020-02-01' }
      ]

      result = described_class
        .reduce(data, period: 'month', metric: 'deployment_frequency')

      expect(result).to eq({ 'January 2020' => 100, 'February 2020' => 20 })
    end
  end

  context 'when metric=lead_time_for_changes' do
    it 'converts from seconds to days' do
      data = [
        { 'value' => 86400, 'date' => '2020-01-01' },
        { 'value' => 43200, 'date' => '2020-01-02' }
      ]

      result = described_class
        .reduce(data, period: 'day', metric: 'lead_time_for_changes')

      expect(result).to eq({ '01 Jan 20' => 1, '02 Jan 20' => 0.5 })
    end
  end

  context 'when metric=time_to_restore_service' do
    it 'converts from seconds to days' do
      data = [
        { 'value' => 86400, 'date' => '2020-01-01' },
        { 'value' => 43200, 'date' => '2020-01-02' }
      ]

      result = described_class
        .reduce(data, period: 'day', metric: 'time_to_restore_service')

      expect(result).to eq({ '01 Jan 20' => 1, '02 Jan 20' => 0.5 })
    end
  end

  context 'when unknown metric is given' do
    it 'raises error' do
      data = [
        { 'value' => 86400, 'date' => '2020-01-01' },
        { 'value' => 43200, 'date' => '2020-01-02' }
      ]

      expect do
        described_class.reduce(data, period: 'day', metric: 'unknown')
      end.to raise_error /Unknown metric is given/
    end
  end

  context 'when unknown period is given' do
    it 'raises error' do
      data = [
        { 'value' => 86400, 'date' => '2020-01-01' },
        { 'value' => 43200, 'date' => '2020-01-02' }
      ]

      expect do
        described_class.reduce(data, period: 'unknown', metric: 'time_to_restore_service')
      end.to raise_error /Unknown period is given/
    end
  end
end
