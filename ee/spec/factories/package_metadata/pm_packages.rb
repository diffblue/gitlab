# frozen_string_literal: true

FactoryBot.define do
  factory :pm_package, class: 'PackageMetadata::Package' do
    purl_type { :npm }
    sequence(:name) { |n| "package-#{n}" }

    initialize_with { PackageMetadata::Package.find_or_initialize_by(name: name, purl_type: purl_type) }
  end
end
