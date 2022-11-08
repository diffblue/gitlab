# frozen_string_literal: true

FactoryBot.define do
  factory :audit_events_streaming_event_type_filter, class: 'AuditEvents::Streaming::EventTypeFilter' do
    sequence :audit_event_type do |i|
      "audit-event-type-#{i}"
    end
    external_audit_event_destination
  end
end
