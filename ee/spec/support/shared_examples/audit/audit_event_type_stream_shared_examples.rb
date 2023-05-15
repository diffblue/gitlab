# frozen_string_literal: true

RSpec.shared_examples 'sends correct event type in audit event stream' do
  it 'sends correct event type in audit event stream' do
    expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
      .with(event_type, anything, anything)

    subject
  end
end
