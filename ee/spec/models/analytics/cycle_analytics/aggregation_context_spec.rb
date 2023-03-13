# frozen_string_literal: true
# frozen_string_literal

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::AggregationContext do
  let(:cursor) { {} }
  let(:runtime_limiter) { instance_double('Analytics::CycleAnalytics::RuntimeLimiter', over_time?: false) }

  subject(:ctx) { described_class.new(cursor: cursor, runtime_limiter: runtime_limiter) }

  it 'removes nil values from the cursor' do
    cursor[:id] = nil
    cursor[:updated_at] = 1

    expect(ctx.cursor).to eq({ updated_at: 1 })
  end

  it 'calculates duration' do
    expect(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(100, 500)

    ctx.processing_start!
    ctx.processing_finished!

    expect(ctx.runtime).to eq(400)
  end

  describe '.over_time?' do
    it { is_expected.not_to be_over_time }

    context 'when runtime limiter is over time' do
      let(:runtime_limiter) { instance_double('Analytics::CycleAnalytics::RuntimeLimiter', over_time?: true) }

      it { is_expected.to be_over_time }
    end
  end
end
