# frozen_string_literal: true

FactoryBot.define do
  factory :alert_management_alert_payload_field, class: 'AlertManagement::AlertPayloadField' do
    project
    path { ['title'] }
    label { 'Title' }
    type { 'string' }

    skip_create
  end
end
