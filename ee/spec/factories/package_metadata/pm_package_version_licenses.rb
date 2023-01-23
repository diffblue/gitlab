# frozen_string_literal: true

FactoryBot.define do
  factory :pm_package_version_license, class: 'PackageMetadata::PackageVersionLicense' do
    package_version { association :pm_package_version }
    license { association :pm_license, package_version_licenses: [instance] }
  end
end
