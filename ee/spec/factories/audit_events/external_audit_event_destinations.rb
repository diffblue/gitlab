# frozen_string_literal: true

FactoryBot.define do
  factory :external_audit_event_destination, class: 'AuditEvents::ExternalAuditEventDestination' do
    group
    destination_url { FFaker::Internet.http_url }
  end
end
