# frozen_string_literal: true

FactoryBot.define do
  factory :instance_audit_events_streaming_header, class: 'AuditEvents::Streaming::InstanceHeader' do
    sequence :key do |i|
      "key-#{i}"
    end
    value { 'bar' }
    instance_external_audit_event_destination
  end
end
