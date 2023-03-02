# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::EventTypeFilters::CreateService, feature_category: :audit_events do
  let_it_be(:destination) { create(:external_audit_event_destination) }
  let_it_be(:event_type_filters) { ['filter_1'] }
  let_it_be(:user) { create(:user) }

  let(:expected_error) { [] }

  subject(:response) do
    described_class.new(destination: destination,
                        event_type_filters: event_type_filters,
                        current_user: user).execute
  end

  describe '#execute' do
    context 'when event type filter is not already present' do
      it 'creates event type filter', :aggregate_failures do
        expect { subject }.to change { destination.event_type_filters.count }.by 1
        expect(destination.event_type_filters.last.audit_event_type).to eq(event_type_filters.first)
        expect(response).to be_success
        expect(response.errors).to match_array(expected_error)
      end

      it 'creates audit event', :aggregate_failures do
        audit_context = {
          name: 'event_type_filters_created',
          author: user,
          scope: destination.group,
          target: destination,
          message: "Created audit event type filter(s): filter_1"
        }

        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)
                                                           .and_call_original

        expect { subject }.to change { AuditEvent.count }.by(1)
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

      it 'does not create audit event' do
        expect { subject }.not_to change { AuditEvent.count }
      end
    end
  end
end
