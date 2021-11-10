# frozen_string_literal: true

FactoryBot.define do
  factory :external_audit_event_destination, class: 'AuditEvents::ExternalAuditEventDestination' do
    group
    sequence(:destination_url) { |n| "#{FFaker::Internet.http_url}/#{n}" }
  end
end
