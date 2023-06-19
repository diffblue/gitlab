# frozen_string_literal: true

FactoryBot.define do
  factory :audit_events_streaming_instance_event_type_filter,
    class: 'AuditEvents::Streaming::InstanceEventTypeFilter' do
    sequence :audit_event_type do |i|
      "audit-event-type-#{i}"
    end
    instance_external_audit_event_destination
  end
end
