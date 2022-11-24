# frozen_string_literal: true

FactoryBot.define do
  factory :geo_dependency_proxy_manifest_state, class: 'Geo::DependencyProxyManifestState' do
    dependency_proxy_manifest

    trait :checksummed do
      verification_checksum { 'abc' }
    end

    trait :checksum_failure do
      verification_failure { 'Could not calculate the checksum' }
    end
  end
end
