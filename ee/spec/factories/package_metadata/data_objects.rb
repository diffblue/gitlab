# frozen_string_literal: true

FactoryBot.define do
  factory :pm_data_object, class: '::PackageMetadata::DataObject' do
    sequence(:name) { |n| "pkg-#{n}" }
    sequence(:version) { |n| "v1.#{n}.0" }
    sequence(:license, %w[MIT Apache unknown LGPL].cycle)
    purl_type { 'npm' }

    trait :with_package do
      pm_package { association(:pm_package, name: name) }
    end

    trait :with_version do
      pm_package { association(:pm_package, name: name) }
      pm_version { association(:pm_package_version, version: version, package: pm_package) }
    end

    trait :with_license do
      pm_license { association(:pm_license, spdx_identifier: license) }
    end

    trait :with_all_relations do
      with_version
      with_license
    end

    trait :with_all_relations_joined do
      pm_package { association(:pm_package, name: name, purl_type: purl_type) }
      pm_version { association(:pm_package_version, version: version, package: pm_package) }
      pm_license { association(:pm_license, spdx_identifier: license) }
      pm_package_version_license do
        association(:pm_package_version_license, package_version: pm_version, license: pm_license)
      end
    end

    initialize_with do
      version = attributes[:pm_version] || attributes[:pm_join]&.package_version
      package = version&.package || attributes[:pm_package]
      license = attributes[:pm_license] || attributes[:pm_join]&.license

      new(*attributes.values_at(:name, :version, :license, :purl_type)).tap do |data_object|
        data_object.package_id = package&.id
        data_object.package_version_id = version&.id
        data_object.license_id = license&.id
      end
    end

    skip_create
  end
end
