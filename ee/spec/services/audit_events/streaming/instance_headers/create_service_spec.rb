# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::Streaming::InstanceHeaders::CreateService, feature_category: :audit_events do
  let_it_be(:destination) { create(:instance_external_audit_event_destination) }
  let(:params) { { destination: destination } }
  let_it_be(:user) { create(:admin) }
  let_it_be(:event_type) { "audit_events_streaming_instance_headers_create" }

  subject(:service) do
    described_class.new(
      params: params,
      current_user: user
    )
  end

  describe '#execute' do
    subject(:response) { service.execute }

    it_behaves_like 'header creation validation errors'

    context 'when the header is created successfully' do
      let(:params) { super().merge(key: 'a_key', value: 'a_value') }

      it_behaves_like 'header creation successful'

      it 'sends the audit streaming event', :aggregate_failures do
        audit_context = {
          name: 'audit_events_streaming_instance_headers_create',
          author: user,
          message: "Created custom HTTP header with key a_key."
        }
        expect(::Gitlab::Audit::Auditor)
          .to receive(:audit)
          .with(hash_including(audit_context))
          .and_call_original

        expect { response }.to change { AuditEvent.count }.from(0).to(1)

        expect(AuditEvent.last).to have_attributes(
          author: user,
          entity_id: Gitlab::Audit::InstanceScope.new.id,
          entity_type: "Gitlab::Audit::InstanceScope",
          details: include(custom_message: 'Created custom HTTP header with key a_key.')
        )
      end
    end
  end
end
