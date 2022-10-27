# frozen_string_literal: true

FactoryBot.define do
  factory :license_scanning_dependency, class: '::Gitlab::Ci::Reports::LicenseScanning::Dependency' do
    name { 'name' }
    path { '.' }

    trait :rails do
      name { 'rails' }
      path { '.' }
    end

    initialize_with { new(name: name, path: path) }

    skip_create
  end
end
