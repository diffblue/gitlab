# frozen_string_literal: true

FactoryBot.define do
  factory :geo_ci_secure_file_state, class: 'Geo::CiSecureFileState' do
    ci_secure_file

    trait(:checksummed) do
      verification_checksum { 'abc' }
    end

    trait(:checksum_failure) do
      verification_failure { 'Could not calculate the checksum' }
    end
  end
end
