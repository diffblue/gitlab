# frozen_string_literal: true

FactoryBot.define do
  factory :pm_affected_package_data_object, class: '::PackageMetadata::AffectedPackageDataObject' do
    purl_type { 'npm' }
    package_name { FFaker::Lorem.word }
    solution { FFaker::Lorem.paragraph }
    affected_range { ">=5.2.0 <5.2.1.1" }
    fixed_versions { %w[5.2.1.1] }

    trait :os_advisory do
      purl_type { :deb }
      distro_version { 'debian 9' }
    end

    initialize_with do
      new(**attributes)
    end

    skip_create
  end
end
