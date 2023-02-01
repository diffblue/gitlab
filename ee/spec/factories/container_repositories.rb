# frozen_string_literal: true

FactoryBot.modify do
  factory :container_repository do
    trait :verification_succeeded do
      verification_checksum { 'abc' }
      verification_state { ContainerRepository.verification_state_value(:verification_succeeded) }
    end

    trait :verification_failed do
      verification_failure { 'Could not calculate the checksum' }
      verification_state { ContainerRepository.verification_state_value(:verification_failed) }
    end
  end
end
