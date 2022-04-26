# frozen_string_literal: true

RSpec.shared_context 'does not create audit event when not licensed' do
  before do
    stub_licensed_features(
      admin_audit_log: false,
      audit_events: false,
      extended_audit_events: false
    )
  end

  it 'does not log any audit event' do
    expect { subject }.not_to change { AuditEvent.count }
  end
end
