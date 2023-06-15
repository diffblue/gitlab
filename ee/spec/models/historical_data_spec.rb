# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HistoricalData do
  before do
    (1..12).each do |i|
      create(:historical_data, recorded_at: Date.new(2014, i, 1), active_user_count: i * 100)
    end
  end

  describe ".during" do
    it "returns the historical data during the specified period" do
      expect(described_class.during(Date.new(2014, 1, 1)..Date.new(2014, 12, 31)).average(:active_user_count)).to eq(650)
    end
  end

  describe ".track!" do
    before do
      allow(User).to receive(:billable).and_return([1, 2, 3, 4, 5])
    end

    it "creates a new historical data record", :freeze_time do
      described_class.track!

      data = described_class.last
      # Database time has microsecond precision, while Ruby time has nanosecond precision,
      # which is why we need the be_within matcher even though we're freezing time.
      expect(data.recorded_at).to be_within(1e-6.seconds).of(Time.current)
      expect(data.active_user_count).to eq(5)
    end
  end

  describe '.max_historical_user_count' do
    subject(:max_historical_user_count) { described_class.max_historical_user_count(from: from, to: to) }

    let(:from) { (Date.current - 1.month).beginning_of_day }
    let(:to) { (Date.current + 1.month).end_of_day }

    context 'with data outside of the given period' do
      context 'with stats before the given period' do
        before do
          create(:historical_data, recorded_at: from - 2.days, active_user_count: 10)
        end

        it 'ignores those records' do
          expect(max_historical_user_count).to eq(0)
        end
      end

      context 'with stats after the given period' do
        before do
          create(:historical_data, recorded_at: to + 2.days, active_user_count: 10)
        end

        it 'ignores those records' do
          expect(max_historical_user_count).to eq(0)
        end
      end
    end

    context 'with data inside of the given period' do
      before do
        create(:historical_data, recorded_at: from + 2.days, active_user_count: 10)
        create(:historical_data, recorded_at: from + 5.days, active_user_count: 15)
      end

      it 'returns max value for active_user_count' do
        expect(max_historical_user_count).to eq(15)
      end
    end
  end
end
