# frozen_string_literal: true

FactoryBot.define do
  factory :pm_affected_package, class: 'PackageMetadata::AffectedPackage' do
    advisory { association :pm_advisory }
    purl_type { :npm }
    package_name { FFaker::Lorem.word }
    solution { FFaker::Lorem.paragraph }
    affected_range { ">=5.2.0 <5.2.1.1" }
    fixed_versions { %w[5.2.1.1] }
    versions do
      [{ 'number' => '1.2.3',
         'commit' => { 'tags' => ['v1.2.3-tag'], 'sha' => '295cf0778821bf08681e2bd0ef0e6cad04fc3001',
                       'timestamp' => '20190626162700' } }]
    end
    overridden_advisory_fields { { title: 'foo', published_date: Date.today - 1.day } }

    trait :os_advisory do
      purl_type { :deb }
      distro_version { 'debian 9' }
    end
  end
end
