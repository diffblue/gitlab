# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::EventTypeFilters::CreateService do
  let_it_be(:destination) { create(:external_audit_event_destination) }
  let_it_be(:event_type_filters) { ['filter_1'] }

  let(:expected_error) { [] }

  subject(:response) do
    described_class.new(destination: destination,
                        event_type_filters: event_type_filters).execute
  end

  describe '#execute' do
    context 'when event type filter is not already present' do
      it 'creates event type filter', :aggregate_failures do
        expect { subject }.to change { destination.event_type_filters.count }.by 1
        expect(destination.event_type_filters.last.audit_event_type).to eq(event_type_filters.first)
        expect(response).to be_success
        expect(response.errors).to match_array(expected_error)
      end
    end

    context 'when record is invalid' do
      let(:expected_error) { 'Validation Failed' }

      before do
        expect_next_instance_of(::AuditEvents::Streaming::EventTypeFilter) do |filter|
          allow(filter).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(filter), expected_error)
        end
      end

      it 'returns error message', :aggregate_failures do
        expect { subject }.not_to change { destination.event_type_filters.count }
        expect(response.errors).to match_array([expected_error])
      end
    end
  end
end
