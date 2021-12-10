# frozen_string_literal: true

FactoryBot.define do
  factory :geo_lfs_object_state, class: 'Geo::LfsObjectState' do
    lfs_object

    trait(:checksummed) do
      verification_checksum { 'abc' }
    end

    trait(:checksum_failure) do
      verification_failure { 'Could not calculate the checksum' }
    end
  end
end
