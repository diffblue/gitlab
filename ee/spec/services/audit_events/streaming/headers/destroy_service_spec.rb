# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::Headers::DestroyService do
  let_it_be(:user) { create(:user) }
  let_it_be(:header) { create(:audit_events_streaming_header) }
  let_it_be(:event_type) { "audit_events_streaming_headers_destroy" }

  let(:destination) { header.external_audit_event_destination }
  let(:params) { { destination: destination, header: header } }

  subject(:service) do
    described_class.new(
      destination: destination,
      current_user: user,
      params: params
    )
  end

  describe '#execute' do
    context 'when no header is provided' do
      let(:params) { super().merge( header: nil) }

      it 'does not destroy the header' do
        expect { service.execute }.not_to change { destination.headers.count }
      end

      it 'has an error response' do
        response = service.execute

        expect(response).to be_error
        expect(response.errors).to match_array ['missing header param']
      end
    end

    context 'when the header is destroyed successfully' do
      let(:response) { service.execute }

      it 'destroys the header' do
        expect { response }.to change { destination.headers.count }.by(-1)
        expect(response).to be_success
      end

      it 'sends the audit streaming event' do
        audit_context = {
          name: 'audit_events_streaming_headers_destroy',
          stream_only: false,
          author: user,
          scope: destination.group,
          target: header,
          message: "Destroyed a custom HTTP header with key #{header.key}."
        }

        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context).and_call_original
        expect { response }.to change { AuditEvent.count }.from(0).to(1)
      end

      context "with license feature external_audit_events" do
        before do
          stub_licensed_features(external_audit_events: true)
        end

        it 'sends correct event type in audit event stream' do
          expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).with(event_type, nil, anything)

          response
        end
      end
    end
  end
end
