# frozen_string_literal: true

FactoryBot.define do
  factory :geo_dependency_proxy_blob_state, class: 'Geo::DependencyProxyBlobState' do
    dependency_proxy_blob

    trait :checksummed do
      verification_checksum { 'abc' }
    end

    trait :checksum_failure do
      verification_failure { 'Could not calculate the checksum' }
    end
  end
end
