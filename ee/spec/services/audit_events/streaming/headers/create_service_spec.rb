# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::Headers::CreateService do
  let_it_be(:user) { create(:user) }
  let_it_be(:destination) { create(:external_audit_event_destination) }
  let_it_be(:event_type) { "audit_events_streaming_headers_create" }

  let(:params) { {} }

  subject(:service) do
    described_class.new(
      current_user: user,
      destination: destination,
      params: params
    )
  end

  describe '#execute' do
    subject(:response) { service.execute }

    context 'when there are validation issues' do
      let(:expected_errors) { ["Key can't be blank", "Value can't be blank"] }

      it 'has an array of errors in the response' do
        expect(response).to be_error
        expect(response.errors).to match_array expected_errors
      end
    end

    context 'when the header is created successfully' do
      let(:params) { super().merge( key: 'a_key', value: 'a_value') }

      it 'has the header in the response payload' do
        expect(response).to be_success
        expect(response.payload[:header].key).to eq 'a_key'
        expect(response.payload[:header].value).to eq 'a_value'
      end

      it 'sends the audit streaming event' do
        audit_context = {
          name: 'audit_events_streaming_headers_create',
          stream_only: false,
          author: user,
          scope: destination.group,
          message: "Created custom HTTP header with key a_key."
        }

        expect(::Gitlab::Audit::Auditor).to receive(:audit)
                                              .with(hash_including(audit_context)).and_call_original
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
