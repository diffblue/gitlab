# frozen_string_literal: true

FactoryBot.define do
  factory :ci_secure_file, class: 'Ci::SecureFile' do
    sequence(:name) { |n| "file#{n}" }
    file { fixture_file_upload('spec/fixtures/ci_secure_files/upload-keystore.jks', 'application/octet-stream') }
    file_store { ::ObjectStorage::Store::LOCAL }
    checksum { 'foo1234' }
    project

    trait :remote_store do
      file_store { ::ObjectStorage::Store::REMOTE }
    end
  end
end
