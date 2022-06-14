# frozen_string_literal: true

FactoryBot.define do
  factory :audit_events_streaming_header, class: 'AuditEvents::Streaming::Header' do
    sequence :key do |i|
      "key-#{i}"
    end
    value { 'bar' }
    external_audit_event_destination
  end
end
