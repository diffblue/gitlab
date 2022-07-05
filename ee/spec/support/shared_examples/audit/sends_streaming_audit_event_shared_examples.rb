# frozen_string_literal: true

RSpec.shared_examples 'sends streaming audit event' do
  before do
    stub_licensed_features(external_audit_events: true)
    group.root_ancestor.external_audit_event_destinations.create!(destination_url: 'http://example.com')
  end

  it 'sends the audit streaming event' do
    expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async).once

    subject
  end
end
