# frozen_string_literal: true

FactoryBot.define do
  factory :pm_sync_config, class: 'PackageMetadata::SyncConfiguration' do
    sequence :storage_type, [:gcp, :offline].cycle
    base_uri { FFaker::Lorem.word }
    sequence :version_format, %w[v1 v2].cycle
    sequence :purl_type, ::Enums::Sbom::PURL_TYPES.keys.cycle

    trait :for_gcp_storage do
      storage_type { :gcp }
      base_uri { 'prod-license-export-bucket' }
    end

    trait :for_offline_storage do
      storage_type { :offline }
      base_uri { PackageMetadata::SyncConfiguration::OFFLINE_STORAGE_LOCATION }
    end

    initialize_with do
      new(*attributes.values)
    end

    skip_create
  end
end
