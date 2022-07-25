# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::Headers::UpdateService do
  let_it_be(:user) { create(:user) }
  let_it_be(:event_type) { "audit_events_streaming_headers_update" }

  let(:header) { create(:audit_events_streaming_header, key: 'old', value: 'old') }
  let(:destination) { header.external_audit_event_destination }
  let(:params) do
    {
      header: header,
      key: 'new',
      value: 'new'
    }
  end

  subject(:service) do
    described_class.new(
      current_user: user,
      destination: destination,
      params: params
    )
  end

  describe '#execute' do
    subject(:response) { service.execute }

    context 'when no header is provided' do
      let(:params) { super().merge( header: nil) }

      it 'does not update the header' do
        expect { subject }.not_to change { header.reload.key }
        expect(header.value).to eq 'old'
      end

      it 'has an error response' do
        expect(response).to be_error
        expect(response.errors).to match_array ['missing header param']
      end
    end

    context 'when the header is updated successfully' do
      it 'updates the header' do
        expect(response).to be_success
        expect(header.reload.key).to eq 'new'
        expect(header.value).to eq 'new'
      end

      it 'sends the audit streaming event' do
        audit_context = {
          name: 'audit_events_streaming_headers_update',
          stream_only: false,
          author: user,
          scope: destination.group,
          target: header,
          message: "Updated a custom HTTP header from key old to have a key new."
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

      context 'when only the header value is updated' do
        let(:params) { super().merge(key: 'old') }

        it 'has a audit message reflecting just the value was changed' do
          audit_context = {
            name: 'audit_events_streaming_headers_update',
            stream_only: false,
            author: user,
            scope: destination.group,
            target: header,
            message: "Updated a custom HTTP header with key old to have a new value."
          }

          expect(::Gitlab::Audit::Auditor).to receive(:audit).with(audit_context)
          response
        end
      end
    end
  end
end
