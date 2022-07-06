# frozen_string_literal: true

FactoryBot.define do
  factory :security_scan, class: 'Security::Scan' do
    scan_type { 'dast' }
    build factory: [:ci_build, :success]
    pipeline { build.pipeline }
    project { build.project }

    trait :with_error do
      info { { errors: [{ type: 'ParsingError', message: 'Unknown error happened' }] } }
    end

    trait :with_warning do
      info { { warnings: [{ type: 'Deprecation Warning', message: 'Schema is deprecated' }] } }
    end

    trait :latest_successful do
      latest { true }
      status { :succeeded }
    end
  end
end
