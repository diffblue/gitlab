# frozen_string_literal: true

FactoryBot.define do
  factory :amazon_s3_configuration, class: 'AuditEvents::AmazonS3Configuration' do
    group
    access_key_xid { SecureRandom.hex(8) }
    sequence :bucket_name do |i|
      "bucket-#{i}"
    end
    aws_region { 'ap-south-2' }
    secret_access_key { SecureRandom.hex(8) }
  end
end
