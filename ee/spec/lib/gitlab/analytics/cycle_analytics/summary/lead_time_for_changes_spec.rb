# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::Summary::LeadTimeForChanges do
  let(:stage) { build(:cycle_analytics_group_stage) }
  let(:user) { build(:user) }

  let(:options) do
    {
      from: 5.days.ago,
      to: 2.days.ago
    }
  end

  subject(:result) { described_class.new(stage: stage, current_user: user, options: options).value }

  context 'when the DORA service returns non-successful status' do
    it 'returns nil' do
      expect_next_instance_of(Dora::AggregateMetricsService) do |service|
        expect(service).to receive(:execute).and_return({ status: :error })
      end

      expect(result).to eq(nil)
    end
  end

  context 'when the DORA service returns 0 as the lead time for changes' do
    it 'returns "none" value' do
      expect_next_instance_of(Dora::AggregateMetricsService) do |service|
        expect(service).to receive(:execute).and_return({ status: :success, data: 0 })
      end

      expect(result.to_s).to eq('-')
    end
  end

  context 'when the DORA service returns the lead time for changes as seconds' do
    it 'returns the value in days' do
      expect_next_instance_of(Dora::AggregateMetricsService) do |service|
        expect(service).to receive(:execute).and_return({ status: :success, data: 5.days.to_i })
      end

      expect(result.to_s).to eq('5.0')
    end
  end
end
