# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter, :clean_gitlab_redis_shared_state do
  let(:merge_request) { build(:merge_request, id: 1) }

  def unique_event_count
    Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(
      event_names: described_class::MR_INVALID_APPROVERS,
      start_date: 2.weeks.ago,
      end_date: 2.weeks.from_now
    )
  end

  describe '.track_invalid_approvers' do
    context 'without any event' do
      it 'returns zero' do
        expect(unique_event_count).to be_zero
      end
    end

    context 'with single MR triggering multiple events' do
      it 'returns one' do
        3.times { described_class.track_invalid_approvers(merge_request: merge_request) }

        expect(unique_event_count).to be(1)
      end
    end

    context 'with two MRs triggering events' do
      let(:merge_request_other) { build(:merge_request, id: 2) }

      it 'returns two' do
        described_class.track_invalid_approvers(merge_request: merge_request)
        described_class.track_invalid_approvers(merge_request: merge_request_other)

        expect(unique_event_count).to be(2)
      end
    end
  end
end
