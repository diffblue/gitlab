# frozen_string_literal: true

FactoryBot.define do
  factory :pm_package, class: 'PackageMetadata::Package' do
    purl_type { :npm }
    sequence(:name) { |n| "package-#{n}" }
    licenses { [[1], 'v0.0.1', 'v1.0.0', [[[2], ['v1.1.0']]]] }

    initialize_with do
      PackageMetadata::Package.find_or_initialize_by(name: name, purl_type: purl_type)
    end
  end
end
