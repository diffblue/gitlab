# frozen_string_literal: true

FactoryBot.modify do
  factory :lfs_object do
    trait(:checksummed) do
      association :lfs_object_state, :checksummed, strategy: :build
    end

    trait(:checksum_failure) do
      association :lfs_object_state, :checksum_failure, strategy: :build
    end

    trait(:verification_succeeded) do
      with_file
      verification_checksum { 'abc' }
      verification_state { ::LfsObject.verification_state_value(:verification_succeeded) }
    end

    trait(:verification_failed) do
      with_file
      verification_failure { 'Could not calculate the checksum' }
      verification_state { ::LfsObject.verification_state_value(:verification_failed) }
    end
  end
end
