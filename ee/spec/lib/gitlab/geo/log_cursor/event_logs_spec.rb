# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Geo::LogCursor::EventLogs,
  :clean_gitlab_redis_shared_state,
  feature_category: :geo_replication do
  subject { described_class.new }

  describe '#fetch_in_batches' do
    context 'when there are no event_logs' do
      it 'does not yield a group of events' do
        expect { |b| subject.fetch_in_batches(&b) }.not_to yield_control
      end
    end

    context 'when there are event logs' do
      let!(:event_log_1) { create(:geo_event_log) }
      let!(:event_log_2) { create(:geo_event_log) }

      context 'when there is no event_log_state' do
        it 'does not yield a group of events' do
          expect { |b| subject.fetch_in_batches(&b) }.not_to yield_with_args([event_log_1, event_log_2])
        end
      end

      context 'when there is already an event_log_state' do
        let(:last_event_id) { event_log_1.id - 1 }

        before do
          create(:geo_event_log_state, event_id: last_event_id)
        end

        it 'saves last event as last processed after yielding' do
          subject.fetch_in_batches { |batch| batch }

          expect(Geo::EventLogState.last.event_id).to eq(event_log_2.id)
        end

        it 'yields a group of events' do
          expect { |b| subject.fetch_in_batches(&b) }.to yield_with_args([event_log_1, event_log_2], last_event_id)
        end
      end
    end
  end
end
