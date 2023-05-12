# frozen_string_literal: true

FactoryBot.define do
  factory :google_cloud_logging_configuration, class: 'AuditEvents::GoogleCloudLoggingConfiguration' do
    group
    sequence :google_project_id_name do |i|
      "#{FFaker::Lorem.word.downcase}-#{SecureRandom.hex(4)}-#{i}"
    end
    client_email { FFaker::Internet.safe_email }
    log_id_name { 'audit_events' }
    private_key { OpenSSL::PKey::RSA.new(4096).to_pem }
  end
end
