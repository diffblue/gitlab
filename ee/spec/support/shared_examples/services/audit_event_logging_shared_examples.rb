# frozen_string_literal: true

RSpec.shared_examples 'audit event logging' do
  context 'when licensed' do
    before do
      stub_licensed_features(extended_audit_events: true)
    end

    context 'when operation succeeds' do
      it 'logs an audit event' do
        if defined?(audit_event_name)
          expect(::Gitlab::Audit::Auditor).to receive(:audit).with(hash_including(
            name: audit_event_name
          )).and_call_original
        end

        expect { operation }.to change(AuditEvent, :count).by(1)
      end

      it 'logs the audit event info' do
        @resource = operation

        expect(AuditEvent.last).to have_attributes(attributes)
      end
    end

    it 'does not log audit event if operation fails' do
      fail_condition!

      expect { operation }.not_to change(AuditEvent, :count)
    end

    it 'does not log audit event if operation results in no change' do
      operation

      expect { operation }.not_to change(AuditEvent, :count)
    end
  end

  context 'when not licensed' do
    before do
      stub_licensed_features(
        admin_audit_log: false,
        audit_events: false,
        extended_audit_events: false
      )
    end

    it 'does not log audit event' do
      expect { operation }.not_to change(AuditEvent, :count)
    end
  end
end

RSpec.shared_examples 'logs the custom audit event' do
  let(:logger) { instance_double(Gitlab::AuditJsonLogger) }

  before do
    stub_licensed_features(audit_events: true)
  end

  it 'creates an event and logs to a file with the provided details' do
    freeze_time do
      expect(service).to receive(:file_logger).and_return(logger)
      expect(logger).to receive(:info).with({ author_id: user.id,
                                              author_name: user.name,
                                              entity_id: entity.id,
                                              entity_type: entity_type,
                                              action: :custom,
                                              ip_address: ip_address,
                                              custom_message: custom_message,
                                              created_at: DateTime.current })

      expect { service.security_event }.to change(AuditEvent, :count).by(1)
      security_event = AuditEvent.last

      expect(security_event.details).to eq({ author_name: user.name,
                                             custom_message: custom_message,
                                             ip_address: ip_address,
                                             action: :custom })
      expect(security_event.author_id).to eq(user.id)
      expect(security_event.entity_id).to eq(entity.id)
      expect(security_event.entity_type).to eq(entity_type)
    end
  end
end

RSpec.shared_examples 'logs the release audit event' do
  let(:logger) { instance_double(Gitlab::AuditJsonLogger) }

  let(:user) { create(:user) }
  let(:ip_address) { '127.0.0.1' }
  let(:entity) { create(:project) }
  let(:target_details) { release.name }
  let(:target_id) { release.id }
  let(:target_type) { 'Release' }
  let(:entity_type) { 'Project' }
  let(:service) { described_class.new(user, entity, ip_address, release) }

  before do
    stub_licensed_features(audit_events: true)
  end

  it 'logs the event to file', :aggregate_failures do
    freeze_time do
      expect(service).to receive(:file_logger).and_return(logger)
      expect(logger).to receive(:info).with({ author_id: user.id,
                                              author_name: user.name,
                                              entity_id: entity.id,
                                              entity_type: entity_type,
                                              ip_address: ip_address,
                                              custom_message: custom_message,
                                              target_details: target_details,
                                              target_id: target_id,
                                              target_type: target_type,
                                              created_at: DateTime.current })

      expect { service.security_event }.to change(AuditEvent, :count).by(1)

      security_event = AuditEvent.last

      expect(security_event.details).to eq({ author_name: user.name,
                                             custom_message: custom_message,
                                             ip_address: ip_address,
                                             target_details: target_details,
                                             target_id: target_id,
                                             target_type: target_type })

      expect(security_event.author_id).to eq(user.id)
      expect(security_event.entity_id).to eq(entity.id)
      expect(security_event.entity_type).to eq(entity_type)
    end
  end
end
