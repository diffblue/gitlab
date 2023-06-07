# frozen_string_literal: true

FactoryBot.define do
  factory :pm_compressed_data_object, class: '::PackageMetadata::CompressedPackageDataObject' do
    sequence(:name) { |n| "pkg-#{n}" }
    purl_type { 'npm' }
    default_licenses { ['MIT'] }
    lowest_version { '1.0.0' }
    highest_version { '1.2.0' }
    other_licenses { [{ 'licenses' => ['Apache'], 'versions' => ['v0.9.0'] }] }

    initialize_with do
      new(**attributes)
    end

    skip_create
  end
end
