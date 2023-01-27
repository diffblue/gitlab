# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::ImpersonationAuditEventService do
  let(:impersonator) { create(:user) }
  let(:ip_address) { '127.0.0.1' }
  let(:message) { 'Impersonation Started' }
  let(:logger) { instance_double(Gitlab::AuditJsonLogger) }
  let(:service) { described_class.new(impersonator, ip_address, message, 3.weeks.ago) }

  describe '#security_event' do
    before do
      stub_licensed_features(extended_audit_events: true)
    end

    it 'creates an event and logs to a file with the provided details' do
      expect(service).to receive(:file_logger).and_return(logger)
      expect(logger).to receive(:info).with({ author_id: impersonator.id,
                                              author_name: impersonator.name,
                                              entity_id: impersonator.id,
                                              entity_type: "User",
                                              action: :custom,
                                              ip_address: ip_address,
                                              custom_message: message,
                                              created_at: anything })

      expect { service.security_event }.to change(AuditEvent, :count).by(1)
      security_event = AuditEvent.last

      expect(security_event.details).to eq({
        author_name: impersonator.name,
        custom_message: message,
        ip_address: ip_address,
        action: :custom
      })
      expect(security_event.author_id).to eq(impersonator.id)
      expect(security_event.entity_id).to eq(impersonator.id)
      expect(security_event.entity_type).to eq('User')
    end
  end
end
