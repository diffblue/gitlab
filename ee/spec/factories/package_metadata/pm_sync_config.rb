# frozen_string_literal: true

FactoryBot.define do
  factory :pm_sync_config, class: 'PackageMetadata::SyncConfiguration' do
    data_type { 'licenses' }
    storage_type { :gcp }
    base_uri { 'prod-license-export-bucket' }
    version_format { 'v1' }
    purl_type { 'npm' }

    trait :for_offline_license_storage do
      storage_type { :offline }
      base_uri { PackageMetadata::SyncConfiguration::Location::LICENSES_PATH }
    end

    initialize_with do
      new(*attributes.values)
    end

    skip_create
  end
end
