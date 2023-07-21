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

    it_behaves_like 'header creation validation errors'

    context 'when the header is created successfully' do
      let(:params) { super().merge( key: 'a_key', value: 'a_value') }

      it_behaves_like 'header creation successful'

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
    end
  end
end
