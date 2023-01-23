# frozen_string_literal: true

FactoryBot.define do
  factory :pm_package_version, class: 'PackageMetadata::PackageVersion' do
    package { association :pm_package }
    sequence(:version) { |n| "v0.0.#{n}" }

    transient do
      spdx_identifiers { [] }
    end

    after(:create) do |package_version, evaluator|
      evaluator.spdx_identifiers.each do |spdx_identifier|
        # rubocop:disable RSpec/FactoryBot/StrategyInCallback
        create(:pm_package_version_license, package_version: package_version,
               license: create(:pm_license, spdx_identifier: spdx_identifier))
        # rubocop:enable RSpec/FactoryBot/StrategyInCallback
      end
    end
  end
end
