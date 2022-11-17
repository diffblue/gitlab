# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::EventTypeFilters::DestroyService do
  let_it_be(:destination) { create(:external_audit_event_destination) }

  subject(:response) { described_class.new(destination: destination, event_type_filters: event_type_filters).execute }

  describe '#execute' do
    context 'when event type filter is not already present' do
      let(:expected_error) { ["Couldn't find event type filters where audit event type(s): filter_2"] }
      let(:event_type_filters) { ['filter_2'] }

      it 'does not delete event type filter', :aggregate_failures do
        expect { subject }.not_to change { destination.event_type_filters.count }
        expect(response.errors).to match_array(expected_error)
      end
    end

    context 'when event type filter is already present' do
      let_it_be(:event_type_filter) do
        create(:audit_events_streaming_event_type_filter,
               external_audit_event_destination: destination)
      end

      let(:expected_error) { [] }
      let(:event_type_filters) { [event_type_filter.audit_event_type] }

      it 'deletes event type filter', :aggregate_failures do
        expect { subject }.to change { destination.event_type_filters.count }.by(-1)
        expect(response).to be_success
        expect(response.errors).to match_array(expected_error)
      end
    end
  end
end
