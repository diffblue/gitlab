# frozen_string_literal: true

FactoryBot.define do
  factory :pm_affected_package, class: 'PackageMetadata::AffectedPackage' do
    advisory { association :pm_advisory }
    purl_type { :npm }
    package_name { FFaker::Lorem.word }
    solution { FFaker::Lorem.paragraph }
    affected_range { ">=5.2.0 <5.2.1.1" }
    overridden_advisory_fields { { title: 'foo', published_date: Date.today - 1.day } }
    trait :os_advisory do
      purl_type { :deb }
      distro_version { 'debian 9' }
    end
  end
end
