# frozen_string_literal: true

FactoryBot.define do
  factory :pm_identifier, class: Hash do
    trait :cve do
      type { 'cve' }
      sequence(:name) { |n| "CVE-#{Date.today.year}-#{n.to_s.rjust(5, '0')}" }
      url { "https://nvd.nist.gov/vuln/detail/#{name}" }
      value { name }
    end

    trait :cwe do
      type { 'cwe' }
      sequence(:name) { |n| "CWE-#{100 + n}" }
      sequence(:url) { |n| "https://cwe.mitre.org/data/definitions/#{100 + n}.html" }
      value { name }
    end

    trait :gemnasium do
      type { 'gemnasium' }
      name { "Gemnasium-#{value}" }
      url { 'https://gitlab.com/gemnasium-db/package.yml' }
      value { '0a647516-66dc-4381-9da7-601193d849e6' }
    end

    skip_create
    initialize_with { attributes }
  end
end
