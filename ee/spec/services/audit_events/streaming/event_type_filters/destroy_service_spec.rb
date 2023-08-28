# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::EventTypeFilters::DestroyService, feature_category: :audit_events do
  let_it_be(:destination) { create(:external_audit_event_destination) }
  let_it_be(:user) { create(:user) }

  subject(:response) do
    described_class.new(destination: destination, event_type_filters: event_type_filters, current_user: user).execute
  end

  describe '#execute' do
    context 'when event type filter is not already present' do
      let(:expected_error) { ["Couldn't find event type filters where audit event type(s): filter_2"] }
      let(:event_type_filters) { ['filter_2'] }

      it 'does not delete event type filter', :aggregate_failures do
        expect { subject }.not_to change { destination.event_type_filters.count }
        expect(response.errors).to match_array(expected_error)
      end

      it 'does not create audit event' do
        expect { subject }.not_to change { AuditEvent.count }
      end
    end

    context 'when event type filter is already present' do
      shared_examples 'destroys event type filter' do
        let(:expected_error) { [] }
        let(:event_type_filters) { [event_type_filter.audit_event_type] }

        it 'deletes event type filter', :aggregate_failures do
          expect { subject }.to change { destination.event_type_filters.count }.by(-1)
          expect(response).to be_success
          expect(response.errors).to match_array(expected_error)
        end

        it 'creates audit event', :aggregate_failures do
          audit_context = {
            name: 'event_type_filters_deleted',
            author: user,
            scope: scope,
            target: destination,
            message: "Deleted audit event type filter(s): #{event_type_filter.audit_event_type}"
          }

          expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)
                                                             .and_call_original

          expect { subject }.to change { AuditEvent.count }.by(1)
        end
      end

      context 'when destination is group level destination' do
        let_it_be(:event_type_filter) do
          create(
            :audit_events_streaming_event_type_filter,
            external_audit_event_destination: destination
          )
        end

        it_behaves_like 'destroys event type filter' do
          let(:scope) { destination.group }
        end
      end

      context 'when destination is instance level destination' do
        let_it_be(:destination) { create(:instance_external_audit_event_destination) }
        let_it_be(:event_type_filter) do
          create(
            :audit_events_streaming_instance_event_type_filter,
            instance_external_audit_event_destination: destination
          )
        end

        it_behaves_like 'destroys event type filter' do
          let(:scope) { be_an_instance_of(Gitlab::Audit::InstanceScope) }
        end
      end
    end
  end
end
