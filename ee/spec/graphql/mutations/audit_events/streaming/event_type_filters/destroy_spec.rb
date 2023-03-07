# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::AuditEvents::Streaming::EventTypeFilters::Destroy, feature_category: :audit_events do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:event_type_filter) { create(:audit_events_streaming_event_type_filter, audit_event_type: 'filter_1') }

  let(:destination) { event_type_filter.external_audit_event_destination }
  let(:group) { destination.group }
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }
  let(:params) do
    {
      destination_id: destination.to_gid,
      event_type_filters: %w[filter_1]
    }
  end

  subject { mutation.resolve(**params) }

  describe '#resolve' do
    context 'when feature is unlicensed' do
      before do
        stub_licensed_features(external_audit_events: false)
      end

      it 'when user is not authorized' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when feature is licensed' do
      before do
        stub_licensed_features(external_audit_events: true)
      end

      context 'when current_user is not group owner' do
        it 'returns useful error messages' do
          expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable, 'The resource that you '\
                 'are attempting to access does not exist or you don\'t have permission to perform this action')
        end
      end

      context 'when current_user is group owner' do
        before do
          group.add_owner(current_user)
        end

        context 'when event type filter is present' do
          it 'deletes the event type filter', :aggregate_failures do
            expect { subject }.to change { destination.event_type_filters.count }.by(-1)
            expect(subject).to eq({ errors: [] })
          end
        end

        context 'when event type filter is not already present' do
          let(:params) do
            {
              destination_id: destination.to_gid,
              event_type_filters: %w[filter_2]
            }
          end

          it 'does not delete event type filter', :aggregate_failures do
            expect { subject }.not_to change { destination.event_type_filters.count }
            expect(subject).to eq({
                                    errors: ["Couldn't find event type filters where audit event type(s): filter_2"]
                                  })
          end
        end
      end
    end
  end
end
