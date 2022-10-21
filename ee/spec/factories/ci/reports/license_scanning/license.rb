# frozen_string_literal: true

FactoryBot.define do
  factory :license_scanning_license, class: '::Gitlab::Ci::Reports::LicenseScanning::License' do
    id { 'ID' }
    name { 'Some License' }
    url { '' }

    trait :mit do
      id { 'MIT' }
      name { 'MIT License' }
      url { 'https://opensource.org/licenses/MIT' }
    end

    trait :unknown do
      id { 'unknown' }
      name { 'Unknown' }
      url { '' }
    end

    initialize_with { new(id: id, name: name, url: url) }

    skip_create
  end
end
