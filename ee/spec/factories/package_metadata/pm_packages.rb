# frozen_string_literal: true

FactoryBot.define do
  factory :pm_package, class: 'PackageMetadata::Package' do
    purl_type { :npm }
    sequence(:name) { |n| "package-#{n}" }

    transient do
      version { '1.0.0' }
      spdx_identifiers { [] }
    end

    initialize_with { PackageMetadata::Package.where(name: name, purl_type: purl_type).first_or_create! }

    after(:create) do |package, evaluator|
      # rubocop:disable RSpec/FactoryBot/StrategyInCallback
      create(:pm_package_version, version: evaluator.version,
             spdx_identifiers: evaluator.spdx_identifiers, package: package)
      # rubocop:enable RSpec/FactoryBot/StrategyInCallback
    end
  end
end
