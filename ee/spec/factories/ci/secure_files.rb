# frozen_string_literal: true

FactoryBot.define do
  factory :ee_ci_secure_file, class: '::Ci::SecureFile', parent: :ci_secure_file do
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
