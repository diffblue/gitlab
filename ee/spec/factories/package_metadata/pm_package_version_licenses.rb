# frozen_string_literal: true

FactoryBot.define do
  factory :pm_package_version_license, class: 'PackageMetadata::PackageVersionLicense' do
    package_version { association :pm_package_version }
    license { association :pm_license }

    transient do
      name { 'package-1' }
      purl_type { 'npm' }
      version { 'v1.0.0' }
      license_name { 'OLDAP-2.0' }
    end

    trait :with_all_relations do
      package_version do
        association(:pm_package_version, :with_package, version: version, name: name, purl_type: purl_type)
      end
      license { association(:pm_license, :with_software_license, spdx_identifier: license_name) }
    end
  end
end
