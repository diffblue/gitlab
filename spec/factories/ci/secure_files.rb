# frozen_string_literal: true

FactoryBot.define do
  factory :ci_secure_file, class: 'Ci::SecureFile' do
    sequence(:name) { |n| "file#{n}" }
    file { fixture_file_upload('spec/fixtures/ci_secure_files/upload-keystore.jks', 'application/octet-stream') }
    checksum { 'foo1234' }
    project

    trait(:verification_succeeded) do
      with_file
      verification_checksum { 'abc' }
      verification_state { Ci::SecureFile.verification_state_value(:verification_succeeded) }
    end

    trait(:verification_failed) do
      with_file
      verification_failure { 'Could not calculate the checksum' }
      verification_state { Ci::SecureFile.verification_state_value(:verification_failed) }
    end
  end
end
