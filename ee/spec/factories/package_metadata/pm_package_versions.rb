# frozen_string_literal: true

FactoryBot.define do
  factory :pm_package_version, class: 'PackageMetadata::PackageVersion' do
    package { association :pm_package }
    sequence(:version) { |n| "v0.0.#{n}" }

    transient do
      name { 'package-1' }
      purl_type { 'npm' }
    end

    trait :with_package do
      package { association(:pm_package, name: name, purl_type: purl_type) }
    end

    initialize_with { PackageMetadata::PackageVersion.find_or_initialize_by(package: package, version: version) }
  end
end
